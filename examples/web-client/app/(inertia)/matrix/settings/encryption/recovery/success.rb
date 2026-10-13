# frozen_string_literal: true

# /matrix/settings/encryption/recovery/success — Recovery set up
#
# Fractal: components/crypto/recovery_setup_view.{blp,rs} (tag success)
#
# The generated recovery key, shown once. There is no second chance to read it, which is the whole content of the screen.
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
#             <Gtk.Label id="success_description" />
#             <Gtk.Box id="success_key_box">
#               <Gtk.Label id="success_key_label" />
#               <Gtk.Button id="success_key_copy_btn" />
#             </Gtk.Box>
#             <Gtk.Button id="success_confirm_btn" />
#           </Gtk.Box>
#         </Adw.Clamp>
#       </Gtk.ScrolledWindow>
#     </Adw.ToolbarView>
#   </Adw.NavigationPage>
#

get "/" do
  render(
    "matrix/settings/encryption/recovery/success",
    recoveryKey: session.delete(:matrix_recovery_key),
    status:      Matrix::Crypto.status,
  )
end

__END__

import { Head, Link } from "@inertiajs/react"
import { Check, Copy, ShieldCheck } from "lucide-react"
import { useState } from "react"

import { Alert, AlertDescription, AlertTitle } from "@/components/reui/alert"
import { Button } from "@/components/ui/button"
import { ShellHeader } from "@/components/admin/slots"

export default function MatrixSettingsEncryptionRecoverySuccess({
  recoveryKey,
  status,
}: {
  recoveryKey: string | null
  status: { recovery: boolean; backup: string | null }
}) {
  const [copied, setCopied] = useState(false)

  const copy = () => {
    if (recoveryKey) {
      void navigator.clipboard.writeText(recoveryKey).then(() => setCopied(true))
    }
  }

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title="Recovery set up" />

      <ShellHeader>
        <h1 className="truncate text-sm font-medium">Account Recovery Set Up Successfully</h1>
      </ShellHeader>

      <div className="mx-auto flex w-full max-w-md flex-col gap-4 p-6">
        <div className="flex flex-col items-center gap-2 py-4">
          <ShieldCheck className="size-10 text-primary" />
          <h2 className="text-center text-xl font-semibold tracking-tight">
            Account Recovery Set Up Successfully
          </h2>
        </div>

        {recoveryKey ? (
          <>
            <Alert variant="warning">
              <AlertTitle>There is no second chance to read this</AlertTitle>
              <AlertDescription>
                Save the recovery key somewhere safe. It is not stored anywhere you can read it
                again, and without it this account cannot be recovered.
              </AlertDescription>
            </Alert>

            <pre className="rounded-md border bg-muted/40 p-4 font-mono text-sm break-all whitespace-pre-wrap">
              {recoveryKey}
            </pre>

            <Button onClick={copy} className="self-start">
              {copied ? <Check className="size-4" /> : <Copy className="size-4" />}
              {copied ? "Copied" : "Copy Recovery Key"}
            </Button>
          </>
        ) : (
          <Alert>
            <AlertTitle>The key was shown once</AlertTitle>
            <AlertDescription>
              It is not kept anywhere this page can read it back. Reset account recovery to get a
              new one.
            </AlertDescription>
          </Alert>
        )}

        <Button variant="outline" render={<Link href="/matrix/settings/encryption" />} className="self-start">
          Done
        </Button>
      </div>
    </div>
  )
}
