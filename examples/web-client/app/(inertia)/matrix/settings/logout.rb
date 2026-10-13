# frozen_string_literal: true

# /matrix/settings/logout — Log out
#
# Fractal: account_settings/general_page/log_out_subpage.{blp,rs}
#
# NOT IMPLEMENTED.
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
  render("matrix/settings/logout")
end

post "/" do
  halt(501, "matrix: not implemented\n")
end

__END__

import { Head, Link } from "@inertiajs/react"
import { ArrowLeft } from "lucide-react"

import { Alert, AlertDescription, AlertTitle } from "@/components/reui/alert"
import { ShellHeader } from "@/components/admin/slots"

export default function MatrixSettingsLogout({}: {

}) {
  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title={"Log out"} />

      <ShellHeader>
        <Link href={"/matrix/settings"} className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">Log out</h1>
      </ShellHeader>

      <div className="mx-auto flex w-full max-w-xl flex-col gap-4 p-6">
        <Alert>
          <AlertTitle>Not implemented</AlertTitle>
          <AlertDescription>
            Scaffolded from Fractal's <code>account_settings/general_page/log_out_subpage.blp</code>. The widget tree to rebuild is in the
            route file.
          </AlertDescription>
        </Alert>
      </div>
    </div>
  )
}
