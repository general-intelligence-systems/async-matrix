# frozen_string_literal: true

# /matrix/settings/encryption/keys — Import and export keys
#
# Fractal: account_settings/encryption_page/import_export_keys_subpage.{blp,rs}
#
# NOT IMPLEMENTED.
#
# Room keys as a passphrase-encrypted file, which is the manual alternative to recovery: the export is every megolm inbound session this device holds.
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
# account_settings/encryption_page/import_export_keys_subpage.blp
#
#   <Adw.NavigationPage id="ImportExportKeysSubpage">
#     <Adw.ToolbarView slot="child">
#       <Adw.HeaderBar />
#       <Gtk.ScrolledWindow id="scrolled_window" slot="content">
#         <Adw.Clamp slot="child">
#           <Gtk.Box id="box" slot="child">
#             <Gtk.Box>
#               <Gtk.Label id="description" />
#               <Gtk.Label id="instructions" />
#             </Gtk.Box>
#             <Gtk.Box>
#               <Gtk.ListBox>
#                 <Adw.PasswordEntryRow id="passphrase" />
#               </Gtk.ListBox>
#               <Gtk.Box id="confirm_passphrase_box">
#                 <Gtk.ListBox>
#                   <Adw.PasswordEntryRow id="confirm_passphrase" />
#                 </Gtk.ListBox>
#                 <Gtk.Revealer id="confirm_passphrase_error_revealer">
#                   <Gtk.Label id="confirm_passphrase_error" slot="child" />
#                 </Gtk.Revealer>
#               </Gtk.Box>
#             </Gtk.Box>
#             <Gtk.ListBox>
#               <Adw.ActionRow id="file_row">
#                 <Gtk.Button id="file_button" />
#               </Adw.ActionRow>
#             </Gtk.ListBox>
#             <Gtk.ListBox>
#               <LoadingButtonRow id="proceed_button" />
#             </Gtk.ListBox>
#           </Gtk.Box>
#         </Adw.Clamp>
#       </Gtk.ScrolledWindow>
#     </Adw.ToolbarView>
#   </Adw.NavigationPage>
#

get "/" do
  render("matrix/settings/encryption/keys")
end

post "/" do
  halt(501, "matrix: not implemented\n")
end

__END__

import { Head, Link } from "@inertiajs/react"
import { ArrowLeft } from "lucide-react"

import { Alert, AlertDescription, AlertTitle } from "@/components/reui/alert"
import { ShellHeader } from "@/components/admin/slots"

export default function MatrixSettingsEncryptionKeys({}: {

}) {
  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title={"Import and export keys"} />

      <ShellHeader>
        <Link href={"/matrix/settings/encryption"} className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">Import and export keys</h1>
      </ShellHeader>

      <div className="mx-auto flex w-full max-w-xl flex-col gap-4 p-6">
        <Alert>
          <AlertTitle>Not implemented</AlertTitle>
          <AlertDescription>
            Scaffolded from Fractal's <code>account_settings/encryption_page/import_export_keys_subpage.blp</code>. The widget tree to rebuild is in the
            route file.
          </AlertDescription>
        </Alert>
      </div>
    </div>
  )
}
