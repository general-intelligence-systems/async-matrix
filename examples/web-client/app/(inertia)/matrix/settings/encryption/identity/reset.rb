# frozen_string_literal: true

# /matrix/settings/encryption/identity/reset — Reset crypto identity
#
# Fractal: components/crypto/identity_setup_view.{blp,rs} (tag reset)
#
# Replacing the cross-signing identity, which un-verifies every other session and every user who had verified this account.
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
# components/crypto/identity_setup_view.blp
#
#   <Adw.NavigationPage>
#     <Adw.ToolbarView slot="child">
#       <Adw.HeaderBar />
#       <Gtk.ScrolledWindow slot="content">
#         <Adw.Clamp slot="child">
#           <Gtk.Box slot="child">
#             <Gtk.Label />
#             <Gtk.Label />
#             <Gtk.Label />
#             <Gtk.Label />
#             <Gtk.Button id="reset_btn" />
#           </Gtk.Box>
#         </Adw.Clamp>
#       </Gtk.ScrolledWindow>
#     </Adw.ToolbarView>
#   </Adw.NavigationPage>
#

get "/" do
  render(
    "matrix/settings/encryption/identity/reset",
    status: Matrix::Crypto.status,
    error:  session.delete(:matrix_crypto_error),
  )
end

post "/" do
  credential = Models::Matrix::Credential.first
  password = params["password"].to_s

  if password.empty?
    auth = nil
  else
    auth = Matrix::Session.password_auth(credential, password)
  end

  Matrix::Crypto.reset_identity!(auth: auth)

  redirect("/matrix/settings/encryption", 303)
rescue Matrix::RoomActions::Error => error
  session[:matrix_crypto_error] = error.message
  redirect("/matrix/settings/encryption/identity/reset", 303)
rescue Async::Matrix::RequestError => error
  session[:matrix_crypto_error] = error.message
  redirect("/matrix/settings/encryption/identity/reset", 303)
end

__END__

import { Form, Head, Link } from "@inertiajs/react"
import { ArrowLeft } from "lucide-react"

import { Alert, AlertDescription, AlertTitle } from "@/components/reui/alert"
import { Button } from "@/components/ui/button"
import { Field, FieldDescription, FieldGroup, FieldLabel } from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import { ShellHeader } from "@/components/admin/slots"

export default function MatrixSettingsEncryptionIdentityReset({
  status,
  error,
}: {
  status: { identity: boolean; recovery: boolean }
  error: string | null
}) {
  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title="Reset crypto identity" />

      <ShellHeader>
        <Link href="/matrix/settings/encryption/identity" className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">Reset Crypto Identity</h1>
      </ShellHeader>

      <div className="mx-auto flex w-full max-w-md flex-col gap-4 p-6">
        {error ? (
          <Alert variant="destructive">
            <AlertTitle>It did not go through</AlertTitle>
            <AlertDescription>{error}</AlertDescription>
          </Alert>
        ) : null}

        <Alert variant="destructive">
          <AlertTitle>This cannot be undone</AlertTitle>
          <AlertDescription>
            A new identity replaces the old one. Every session you verified becomes unverified, and
            everyone who verified you sees an alert until they verify you again.
            {status.recovery ? " Account recovery keeps the old keys until it is reset too." : ""}
          </AlertDescription>
        </Alert>

        <Form action="/matrix/settings/encryption/identity/reset" method="post" className="flex flex-col gap-4">
          {({ processing }) => (
            <>
              <FieldGroup>
                <Field>
                  <FieldLabel htmlFor="password">Account password</FieldLabel>
                  <Input id="password" name="password" type="password" autoComplete="current-password" />
                  <FieldDescription>
                    Only needed where the homeserver asks for it before replacing keys.
                  </FieldDescription>
                </Field>
              </FieldGroup>

              <Button type="submit" variant="destructive" disabled={processing} className="self-start">
                Reset Crypto Identity
              </Button>
            </>
          )}
        </Form>
      </div>
    </div>
  )
}
