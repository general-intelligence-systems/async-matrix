# frozen_string_literal: true

# /matrix/settings/password — Change password
#
# Fractal: account_settings/general_page/change_password_subpage.{ui,rs}
#
# The one screen Fractal still writes as GtkBuilder XML rather than Blueprint, which is why it is
# missing from a .blp listing of its views.
#
# Only reachable on a homeserver which owns the password: Fractal keeps the row hidden otherwise
# (general_page/mod.blp change_password_row is `visible: false` until it knows), because an OAuth
# account's password lives at the authorization server.
# ── Fractal's widget tree ──────────────────────────────────────────────────
#
# COMPONENT NAMES ONLY, extracted from the Blueprint sources named below --
# properties, bindings, styles and handlers are dropped. This is the STRUCTURE
# to rebuild, not a prescription: an Adw.ActionRow is a GTK list row, and what
# it becomes in shadcn/reui is the next decision, not one this records.
#
# Adw.* is libadwaita, which is where the patterns live (PreferencesPage ->
# PreferencesGroup -> ActionRow is GNOME's settings idiom). Gtk.* is plain
# GTK. A bare <Name> with no prefix is one of Fractal's own widgets, and gets
# its own tree below if this view is where it is built.
#
# account_settings/general_page/change_password_subpage.ui
#
#   <Adw.ToolbarView>
#     <Adw.HeaderBar />
#     <Gtk.ScrolledWindow id="scrolled_window">
#       <Adw.Clamp>
#         <Gtk.Box id="box">
#           <Gtk.Image />
#           <Gtk.Box>
#             <Gtk.Label />
#           </Gtk.Box>
#           <Gtk.Box>
#             <Gtk.Box>
#               <Gtk.ListBox>
#                 <Adw.PasswordEntryRow id="password" />
#               </Gtk.ListBox>
#               <Gtk.LevelBar id="password_progress" />
#               <Gtk.Revealer id="password_error_revealer">
#                 <Gtk.Label id="password_error" />
#               </Gtk.Revealer>
#             </Gtk.Box>
#             <Gtk.Box>
#               <Gtk.ListBox>
#                 <Adw.PasswordEntryRow id="confirm_password" />
#               </Gtk.ListBox>
#               <Gtk.Revealer id="confirm_password_error_revealer">
#                 <Gtk.Label id="confirm_password_error" />
#               </Gtk.Revealer>
#             </Gtk.Box>
#           </Gtk.Box>
#           <Gtk.ListBox>
#             <LoadingButtonRow id="button" />
#           </Gtk.ListBox>
#         </Gtk.Box>
#       </Adw.Clamp>
#     </Gtk.ScrolledWindow>
#   </Adw.ToolbarView>
#

get "/" do
  credential = Models::Matrix::Credential.first

  render(
    "matrix/settings/password",
    account: { userId: credential&.matrix_user_id },
    oauth:   !Matrix::Session.oauth_client(credential).nil?,
    error:   session.delete(:matrix_password_error),
  )
end

post "/" do
  credential = Models::Matrix::Credential.first || halt(404, "matrix: not signed in\n")

  unless Matrix::Session.oauth_client(credential).nil?
    halt(409, "matrix: this account's password is the authorization server's\n")
  end

  if params["new_password"].to_s.length < 8
    session[:matrix_password_error] = "that is shorter than eight characters"
    redirect("/matrix/settings/password", 303)
  end

  unless params["new_password"].to_s == params["confirm_password"].to_s
    session[:matrix_password_error] = "the two passwords do not match"
    redirect("/matrix/settings/password", 303)
  end

  done = Matrix::Session.change_password!(
    credential,
    params["new_password"].to_s,
    params["password"].to_s,
    logout_devices: params["logout_devices"].to_s == "true",
  )

  if done.nil?
    session[:matrix_password_error] = "the homeserver refused: check the current password"
    redirect("/matrix/settings/password", 303)
  end

  redirect("/matrix/settings", 303)
end

__END__

import { Form, Head, Link } from "@inertiajs/react"
import { ArrowLeft } from "lucide-react"

import { Alert, AlertDescription, AlertTitle } from "@/components/reui/alert"
import { Button } from "@/components/ui/button"
import { Field, FieldDescription, FieldGroup, FieldLabel } from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import { Switch } from "@/components/ui/switch"
import { ShellHeader } from "@/components/admin/slots"

export default function MatrixSettingsPassword({
  account,
  oauth,
  error,
}: {
  account: { userId: string | null }
  oauth: boolean
  error: string | null
}) {
  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title="Change password" />

      <ShellHeader>
        <Link href="/matrix/settings" className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">Change password</h1>
      </ShellHeader>

      <div className="mx-auto flex w-full max-w-xl flex-col gap-4 p-6">
        {oauth ? (
          <Alert>
            <AlertTitle>Not this homeserver's to change</AlertTitle>
            <AlertDescription>
              This account signs in through an authorization server, which owns the password.
            </AlertDescription>
          </Alert>
        ) : (
          <>
            {error ? (
              <Alert variant="destructive">
                <AlertTitle>Not changed</AlertTitle>
                <AlertDescription>{error}</AlertDescription>
              </Alert>
            ) : null}

            <Form action="/matrix/settings/password" method="post" className="flex flex-col gap-4">
              {({ processing }) => (
                <>
                  <FieldGroup>
                    <Field>
                      <FieldLabel htmlFor="password">Current password</FieldLabel>
                      <Input id="password" name="password" type="password" autoComplete="current-password" />
                    </Field>
                    <Field>
                      <FieldLabel htmlFor="new_password">New password</FieldLabel>
                      <Input id="new_password" name="new_password" type="password" autoComplete="new-password" />
                      <FieldDescription>At least eight characters.</FieldDescription>
                    </Field>
                    <Field>
                      <FieldLabel htmlFor="confirm_password">Confirm new password</FieldLabel>
                      <Input id="confirm_password" name="confirm_password" type="password" autoComplete="new-password" />
                    </Field>
                    <Field orientation="horizontal">
                      <FieldLabel htmlFor="logout_devices">Sign out other devices</FieldLabel>
                      <Switch id="logout_devices" name="logout_devices" value="true" />
                    </Field>
                  </FieldGroup>

                  <Button type="submit" disabled={processing} className="self-start">
                    Change password
                  </Button>
                </>
              )}
            </Form>
          </>
        )}
      </div>
    </div>
  )
}
