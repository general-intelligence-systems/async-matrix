# frozen_string_literal: true

# /matrix/settings/deactivate — Deactivate account
#
# Fractal: account_settings/general_page/deactivate_account_subpage.{blp,rs}
#
# NOT IMPLEMENTED.
#
# Deactivation, which is irreversible and needs the user id typed back to confirm.
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
# account_settings/general_page/deactivate_account_subpage.blp
#
#   <Adw.NavigationPage id="DeactivateAccountSubpage">
#     <Adw.ToolbarView slot="child">
#       <Adw.HeaderBar />
#       <Gtk.ScrolledWindow id="scrolled_window" slot="content">
#         <Adw.Clamp slot="child">
#           <Gtk.Box id="box" slot="child">
#             <Gtk.Image />
#             <Gtk.Box>
#               <Gtk.Label />
#               <Gtk.Label />
#             </Gtk.Box>
#             <Gtk.ListBox>
#               <Adw.EntryRow id="confirmation" />
#               <LoadingButtonRow id="loading_button" />
#               <Adw.ButtonRow id="open_url_button" />
#             </Gtk.ListBox>
#           </Gtk.Box>
#         </Adw.Clamp>
#       </Gtk.ScrolledWindow>
#     </Adw.ToolbarView>
#   </Adw.NavigationPage>
#

get "/" do
  credential = Models::Matrix::Credential.first

  render(
    "matrix/settings/deactivate",
    account: { userId: credential&.matrix_user_id },
    oauth:   !Matrix::Session.oauth_client(credential).nil?,
    error:   session.delete(:matrix_deactivate_error),
  )
end

# Irreversible, and the user id is typed back to confirm it. User-interactive auth wants the
# password, which an OAuth session does not have -- the authorization server owns that, so it is
# sent there instead.
post "/" do
  credential = Models::Matrix::Credential.first || halt(404, "matrix: not signed in\n")

  unless params["confirm"].to_s == credential.matrix_user_id.to_s
    session[:matrix_deactivate_error] = "that is not this account's user id"
    redirect("/matrix/settings/deactivate", 303)
  end

  done = Matrix::Session.deactivate!(
    credential,
    params["password"].to_s,
    erase: params["erase"].to_s == "true",
  )

  if done.nil?
    session[:matrix_deactivate_error] = "the homeserver refused: check the password and try again"
    redirect("/matrix/settings/deactivate", 303)
  end

  redirect("/matrix/login", 303)
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

export default function MatrixSettingsDeactivate({
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
      <Head title="Deactivate account" />

      <ShellHeader>
        <Link href="/matrix/settings" className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">Deactivate account</h1>
      </ShellHeader>

      <div className="mx-auto flex w-full max-w-xl flex-col gap-4 p-6">
        <Alert variant="destructive">
          <AlertTitle>This cannot be undone</AlertTitle>
          <AlertDescription>
            The account is closed for good. The user id can never be reused, and messages already
            sent stay where they are.
          </AlertDescription>
        </Alert>

        {error ? (
          <Alert variant="destructive">
            <AlertTitle>Not deactivated</AlertTitle>
            <AlertDescription>{error}</AlertDescription>
          </Alert>
        ) : null}

        <Form action="/matrix/settings/deactivate" method="post" className="flex flex-col gap-4">
          {({ processing }) => (
            <>
              <FieldGroup>
                <Field>
                  <FieldLabel htmlFor="confirm">Type your user id to confirm</FieldLabel>
                  <Input id="confirm" name="confirm" autoComplete="off" spellCheck={false} />
                  <FieldDescription>{account.userId}</FieldDescription>
                </Field>

                {oauth ? null : (
                  <Field>
                    <FieldLabel htmlFor="password">Password</FieldLabel>
                    <Input id="password" name="password" type="password" />
                  </Field>
                )}

                <Field orientation="horizontal">
                  <FieldLabel htmlFor="erase">Erase my messages</FieldLabel>
                  <Switch id="erase" name="erase" value="true" />
                </Field>
              </FieldGroup>

              <Button type="submit" variant="destructive" disabled={processing} className="self-start">
                Deactivate account
              </Button>
            </>
          )}
        </Form>
      </div>
    </div>
  )
}
