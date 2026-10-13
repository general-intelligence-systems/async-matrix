# frozen_string_literal: true

# /matrix/settings/encryption/recovery/success — Recovery set up
#
# Fractal: components/crypto/recovery_setup_view.{blp,rs} (tag success)
#
# NOT IMPLEMENTED.
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
  render("matrix/settings/encryption/recovery/success")
end

post "/" do
  halt(501, "matrix: not implemented\n")
end

__END__

import { Head, Link } from "@inertiajs/react"
import { ArrowLeft } from "lucide-react"

import { Alert, AlertDescription, AlertTitle } from "@/components/reui/alert"
import { ShellHeader } from "@/components/admin/slots"

export default function MatrixSettingsEncryptionRecoverySuccess({}: {

}) {
  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title={"Recovery set up"} />

      <ShellHeader>
        <Link href={"/matrix/settings/encryption/recovery"} className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">Recovery set up</h1>
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
