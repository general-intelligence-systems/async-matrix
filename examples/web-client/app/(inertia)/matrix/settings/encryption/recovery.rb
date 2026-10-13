# frozen_string_literal: true

# /matrix/settings/encryption/recovery — Recover account
#
# Fractal: components/crypto/recovery_setup_view.{blp,rs} (tag recover)
#
# Unlocking m.secret_storage with the recovery passphrase or key, which is what restores the key backup and the cross-signing secrets to a fresh device.
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
#   <Adw.NavigationPage>
#     <Adw.ToolbarView slot="child">
#       <Adw.HeaderBar />
#       <Gtk.ScrolledWindow slot="content">
#         <Adw.Clamp slot="child">
#           <Gtk.Box slot="child">
#             <Gtk.Label />
#             <Gtk.Label />
#             <Gtk.Label />
#             <Gtk.ListBox>
#               <Adw.PasswordEntryRow id="recover_entry" />
#             </Gtk.ListBox>
#             <LoadingButton id="recover_btn" />
#             <Gtk.Label />
#             <Gtk.Button />
#           </Gtk.Box>
#         </Adw.Clamp>
#       </Gtk.ScrolledWindow>
#     </Adw.ToolbarView>
#   </Adw.NavigationPage>
#

get "/" do
  render(
    "matrix/settings/encryption/recovery",
    status:     Matrix::Crypto.status,
    passphrase: Matrix::Crypto.passphrase?,
    error:      session.delete(:matrix_crypto_error),
  )
end

post "/" do
  secret = params["secret"].to_s

  if secret.empty?
    session[:matrix_crypto_error] = "Recovery Passphrase or Key"
    redirect("/matrix/settings/encryption/recovery", 303)
  end

  answer = Matrix::Crypto.recover!(secret)

  if answer[:missing].empty?
    redirect("/matrix/settings/encryption", 303)
  else
    redirect("/matrix/settings/encryption/recovery/incomplete", 303)
  end
rescue Matrix::RoomActions::Error => error
  session[:matrix_crypto_error] = error.message
  redirect("/matrix/settings/encryption/recovery", 303)
rescue Async::Matrix::RequestError => error
  session[:matrix_crypto_error] = error.message
  redirect("/matrix/settings/encryption/recovery", 303)
end

__END__

import { Form, Head, Link } from "@inertiajs/react"
import { ArrowLeft } from "lucide-react"

import { Alert, AlertDescription, AlertTitle } from "@/components/reui/alert"
import { Button } from "@/components/ui/button"
import { Field, FieldDescription, FieldGroup, FieldLabel } from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import { ShellHeader } from "@/components/admin/slots"

export default function MatrixSettingsEncryptionRecovery({
  status,
  passphrase,
  error,
}: {
  status: { identity: boolean; recovery: boolean; missing: string[] }
  passphrase: boolean
  error: string | null
}) {
  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title="Recover account" />

      <ShellHeader>
        <Link href="/matrix/settings/encryption" className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">Recover Account</h1>
      </ShellHeader>

      <div className="mx-auto flex w-full max-w-md flex-col gap-4 p-6">
        <h2 className="text-xl font-semibold tracking-tight">Recover Account</h2>
        <p className="text-sm text-muted-foreground">Restore full access to your account.</p>

        {error ? (
          <Alert variant="destructive">
            <AlertTitle>It did not open</AlertTitle>
            <AlertDescription>{error}</AlertDescription>
          </Alert>
        ) : null}

        {status.recovery ? null : (
          <Alert variant="warning">
            <AlertTitle>Nothing to recover from</AlertTitle>
            <AlertDescription>
              This account has no recovery set up, so there is nowhere to read the keys back from.{" "}
              <Link href="/matrix/settings/encryption/recovery/enable" className="underline">
                Set it up
              </Link>
            </AlertDescription>
          </Alert>
        )}

        <Form action="/matrix/settings/encryption/recovery" method="post" className="flex flex-col gap-4">
          {({ processing }) => (
            <>
              <FieldGroup>
                <Field>
                  <FieldLabel htmlFor="secret">Recovery Passphrase or Key</FieldLabel>
                  <Input
                    id="secret"
                    name="secret"
                    type="password"
                    autoComplete="off"
                    autoFocus
                    spellCheck={false}
                  />
                  <FieldDescription>
                    {passphrase
                      ? "This account's recovery was set up with a passphrase."
                      : "This account's recovery uses a generated key, written in groups of four characters."}
                  </FieldDescription>
                </Field>
              </FieldGroup>

              <Button type="submit" disabled={processing || !status.recovery} className="self-start">
                Recover
              </Button>
            </>
          )}
        </Form>

        <Button
          variant="ghost"
          size="sm"
          render={<Link href="/matrix/settings/encryption/recovery/reset" />}
          className="self-start"
        >
          I have lost it
        </Button>
      </div>
    </div>
  )
}
