# frozen_string_literal: true

# /matrix/settings/encryption/recovery/reset — Reset account recovery
#
# Fractal: components/crypto/recovery_setup_view.{blp,rs} (tag reset)
#
# Replacing secret storage when the passphrase is lost, which discards the existing backup and the identity that signed it.
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
# components/crypto/recovery_setup_view.blp
#
#   <Adw.NavigationPage id="reset_page">
#     <Adw.ToolbarView slot="child">
#       <Adw.HeaderBar />
#       <Gtk.ScrolledWindow slot="content">
#         <Adw.Clamp slot="child">
#           <Gtk.Box slot="child">
#             <Gtk.Label />
#             <Gtk.Label />
#             <Gtk.ListBox>
#               <SwitchLoadingRow id="reset_identity_row" />
#               <SwitchLoadingRow id="reset_backup_row" />
#             </Gtk.ListBox>
#             <Gtk.Label />
#             <Gtk.Label />
#             <Gtk.ListBox>
#               <Adw.PasswordEntryRow id="reset_entry" />
#             </Gtk.ListBox>
#             <LoadingButton id="reset_btn" />
#           </Gtk.Box>
#         </Adw.Clamp>
#       </Gtk.ScrolledWindow>
#     </Adw.ToolbarView>
#   </Adw.NavigationPage>
#

get "/" do
  render(
    "matrix/settings/encryption/recovery/reset",
    status: Matrix::Crypto.status,
    error:  session.delete(:matrix_crypto_error),
  )
end

post "/" do
  passphrase = params["passphrase"].to_s
  confirm = params["confirm_passphrase"].to_s

  unless passphrase.empty? || passphrase == confirm
    session[:matrix_crypto_error] = "Passphrases do not match"
    redirect("/matrix/settings/encryption/recovery/reset", 303)
  end

  session[:matrix_recovery_key] = Matrix::Crypto.reset_recovery!(passphrase)

  redirect("/matrix/settings/encryption/recovery/success", 303)
rescue Matrix::RoomActions::Error => error
  session[:matrix_crypto_error] = error.message
  redirect("/matrix/settings/encryption/recovery/reset", 303)
rescue Async::Matrix::RequestError => error
  session[:matrix_crypto_error] = error.message
  redirect("/matrix/settings/encryption/recovery/reset", 303)
end

__END__

import { Form, Head, Link } from "@inertiajs/react"
import { ArrowLeft } from "lucide-react"

import { Alert, AlertDescription, AlertTitle } from "@/components/reui/alert"
import { Button } from "@/components/ui/button"
import { Field, FieldDescription, FieldGroup, FieldLabel } from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import { ShellHeader } from "@/components/admin/slots"

export default function MatrixSettingsEncryptionRecoveryReset({
  status,
  error,
}: {
  status: { identity: boolean; recovery: boolean; backup: string | null }
  error: string | null
}) {
  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title="Reset account recovery" />

      <ShellHeader>
        <Link href="/matrix/settings/encryption/recovery" className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">Reset Account Recovery</h1>
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
            What the old recovery held becomes unreadable. Any message whose keys were only in the
            backup stays unreadable, and every session has to be verified again.
          </AlertDescription>
        </Alert>

        <Form action="/matrix/settings/encryption/recovery/reset" method="post" className="flex flex-col gap-4">
          {({ processing }) => (
            <>
              <FieldGroup>
                <Field>
                  <FieldLabel htmlFor="passphrase">New recovery passphrase</FieldLabel>
                  <Input id="passphrase" name="passphrase" type="password" autoComplete="new-password" />
                  <FieldDescription>
                    If you do not provide a recovery passphrase, a recovery key will be created.
                  </FieldDescription>
                </Field>
                <Field>
                  <FieldLabel htmlFor="confirm_passphrase">Confirm passphrase</FieldLabel>
                  <Input
                    id="confirm_passphrase"
                    name="confirm_passphrase"
                    type="password"
                    autoComplete="new-password"
                  />
                </Field>
              </FieldGroup>

              <Button type="submit" variant="destructive" disabled={processing} className="self-start">
                Reset Account Recovery
              </Button>
            </>
          )}
        </Form>
      </div>
    </div>
  )
}
