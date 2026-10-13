# frozen_string_literal: true

# /matrix/settings/logout — Log out
#
# Fractal: account_settings/general_page/log_out_subpage.{blp,rs}
#
# What logging out costs when recovery is not set up: the room keys on this device go with it.
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
# account_settings/general_page/log_out_subpage.blp
#
#   <Adw.NavigationPage id="LogOutSubpage">
#     <Gtk.Stack id="stack" slot="child">
#       <Gtk.StackPage>
#         <Adw.ToolbarView slot="child">
#           <Adw.HeaderBar />
#           <Gtk.ScrolledWindow slot="content">
#             <Adw.Clamp slot="child">
#               <Gtk.Box slot="child">
#                 <Gtk.Image />
#                 <Gtk.Label />
#                 <Gtk.Box id="warning_box">
#                   <Gtk.Label id="warning_description" />
#                   <Gtk.ListBox>
#                     <Adw.ButtonRow id="warning_button" />
#                   </Gtk.ListBox>
#                 </Gtk.Box>
#                 <Gtk.ListBox>
#                   <LoadingButtonRow id="logout_button" />
#                 </Gtk.ListBox>
#               </Gtk.Box>
#             </Adw.Clamp>
#           </Gtk.ScrolledWindow>
#         </Adw.ToolbarView>
#       </Gtk.StackPage>
#       <Gtk.StackPage>
#         <Adw.ToolbarView slot="child">
#           <Adw.HeaderBar />
#           <Gtk.ScrolledWindow slot="content">
#             <Adw.Clamp slot="child">
#               <Gtk.Box slot="child">
#                 <Gtk.Label />
#                 <Gtk.ListBox>
#                   <LoadingButtonRow id="try_again_button" />
#                 </Gtk.ListBox>
#                 <Gtk.Label />
#                 <Gtk.ListBox>
#                   <LoadingButtonRow id="remove_button" />
#                 </Gtk.ListBox>
#               </Gtk.Box>
#             </Adw.Clamp>
#           </Gtk.ScrolledWindow>
#         </Adw.ToolbarView>
#       </Gtk.StackPage>
#     </Gtk.Stack>
#   </Adw.NavigationPage>
#

get "/" do
  credential = Models::Matrix::Credential.first

  render(
    "matrix/settings/logout",
    account:  {
      userId:   credential&.matrix_user_id,
      deviceId: credential&.device_id,
    },
    oauth:    !Matrix::Session.oauth_client(credential).nil?,
    recovery: !Models::Matrix::DeviceState.first&.keys_published.nil?,
  )
end

# An OAuth session is ended by revoking the token at the authorization server; a native one by
# POST /logout. Either way the row goes, and with it the only copy of this device's room keys.
post "/" do
  credential = Models::Matrix::Credential.first || halt(404, "matrix: not signed in\n")

  Matrix::Session.log_out!(credential, everywhere: params["everywhere"].to_s == "true")

  redirect("/matrix/login", 303)
end

__END__

import { Form, Head, Link } from "@inertiajs/react"
import { ArrowLeft } from "lucide-react"

import { Alert, AlertDescription, AlertTitle } from "@/components/reui/alert"
import { Button } from "@/components/ui/button"
import { Field, FieldLabel } from "@/components/ui/field"
import { Switch } from "@/components/ui/switch"
import { ShellHeader } from "@/components/admin/slots"

export default function MatrixSettingsLogout({
  account,
  oauth,
  recovery,
}: {
  account: { userId: string | null; deviceId: string | null }
  oauth: boolean
  recovery: boolean
}) {
  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title="Log out" />

      <ShellHeader>
        <Link href="/matrix/settings" className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">Log out</h1>
      </ShellHeader>

      <div className="mx-auto flex w-full max-w-xl flex-col gap-4 p-6">
        {recovery ? null : (
          <Alert variant="warning">
            <AlertTitle>Account recovery is not set up</AlertTitle>
            <AlertDescription>
              The room keys on this device go with it, and encrypted history will not be readable
              on a new session.
            </AlertDescription>
          </Alert>
        )}

        <Alert>
          <AlertTitle>Signing out {account.userId}</AlertTitle>
          <AlertDescription>
            Device {account.deviceId}. {oauth ? "The token is revoked at the authorization server." : "The homeserver is told to end the session."}
          </AlertDescription>
        </Alert>

        <Form action="/matrix/settings/logout" method="post" className="flex flex-col gap-4">
          {({ processing }) => (
            <>
              {oauth ? null : (
                <Field orientation="horizontal">
                  <FieldLabel htmlFor="everywhere">Every device</FieldLabel>
                  <Switch id="everywhere" name="everywhere" value="true" />
                </Field>
              )}

              <Button type="submit" variant="destructive" disabled={processing} className="self-start">
                Log out
              </Button>
            </>
          )}
        </Form>
      </div>
    </div>
  )
}
