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
  render("matrix/settings/deactivate")
end

post "/" do
  halt(501, "matrix: not implemented\n")
end

__END__

import { Head, Link } from "@inertiajs/react"
import { ArrowLeft } from "lucide-react"

import { Alert, AlertDescription, AlertTitle } from "@/components/reui/alert"
import { ShellHeader } from "@/components/admin/slots"

export default function MatrixSettingsDeactivate({}: {

}) {
  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title={"Deactivate account"} />

      <ShellHeader>
        <Link href={"/matrix/settings"} className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">Deactivate account</h1>
      </ShellHeader>

      <div className="mx-auto flex w-full max-w-xl flex-col gap-4 p-6">
        <Alert>
          <AlertTitle>Not implemented</AlertTitle>
          <AlertDescription>
            Scaffolded from Fractal's <code>account_settings/general_page/deactivate_account_subpage.blp</code>. The widget tree to rebuild is in the
            route file.
          </AlertDescription>
        </Alert>
      </div>
    </div>
  )
}
