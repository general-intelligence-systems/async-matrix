# frozen_string_literal: true

# /matrix/settings/encryption/recovery — Recover account
#
# Fractal: components/crypto/recovery_setup_view.{blp,rs} (tag recover)
#
# NOT IMPLEMENTED.
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
  render("matrix/settings/encryption/recovery")
end

post "/" do
  halt(501, "matrix: not implemented\n")
end

__END__

import { Head, Link } from "@inertiajs/react"
import { ArrowLeft } from "lucide-react"

import { Alert, AlertDescription, AlertTitle } from "@/components/reui/alert"
import { ShellHeader } from "@/components/admin/slots"

export default function MatrixSettingsEncryptionRecovery({}: {

}) {
  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title={"Recover account"} />

      <ShellHeader>
        <Link href={"/matrix/settings/encryption"} className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">Recover account</h1>
      </ShellHeader>

      <div className="mx-auto flex w-full max-w-xl flex-col gap-4 p-6">
        <Alert>
          <AlertTitle>Not implemented</AlertTitle>
          <AlertDescription>
            Scaffolded from Fractal's <code>components/crypto/recovery_setup_view.blp</code>. The widget tree to rebuild is in the
            route file.
          </AlertDescription>
        </Alert>
      </div>
    </div>
  )
}
