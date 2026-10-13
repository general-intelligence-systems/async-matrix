# frozen_string_literal: true

# /matrix/settings/safety/ignored — Ignored users
#
# Fractal: account_settings/safety_page/ignored_users_subpage/
#
# NOT IMPLEMENTED.
#
# The m.ignored_user_list, as a list you can remove from.
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
# account_settings/safety_page/ignored_users_subpage/mod.blp
#
#   <Adw.NavigationPage id="IgnoredUsersSubpage">
#     <Gtk.Stack id="stack">
#       <Gtk.StackPage>
#         <Adw.ToolbarView slot="child">
#           <Adw.HeaderBar>
#             <Gtk.ToggleButton id="search_button" />
#           </Adw.HeaderBar>
#           <Gtk.SearchBar id="search_bar">
#             <Adw.Clamp slot="child">
#               <Gtk.SearchEntry id="search_entry" />
#             </Adw.Clamp>
#           </Gtk.SearchBar>
#           <Gtk.ScrolledWindow slot="content">
#             <Adw.ClampScrollable slot="child">
#               <Gtk.ListView id="list_view" slot="child" />
#             </Adw.ClampScrollable>
#           </Gtk.ScrolledWindow>
#         </Adw.ToolbarView>
#       </Gtk.StackPage>
#       <Gtk.StackPage>
#         <Adw.ToolbarView slot="child">
#           <Adw.HeaderBar />
#           <Adw.StatusPage slot="content" />
#         </Adw.ToolbarView>
#       </Gtk.StackPage>
#     </Gtk.Stack>
#   </Adw.NavigationPage>
#

get "/" do
  render("matrix/settings/safety/ignored")
end

post "/" do
  halt(501, "matrix: not implemented\n")
end

__END__

import { Head, Link } from "@inertiajs/react"
import { ArrowLeft } from "lucide-react"

import { Alert, AlertDescription, AlertTitle } from "@/components/reui/alert"
import { ShellHeader } from "@/components/admin/slots"

export default function MatrixSettingsSafetyIgnored({}: {

}) {
  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title={"Ignored users"} />

      <ShellHeader>
        <Link href={"/matrix/settings/safety"} className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">Ignored users</h1>
      </ShellHeader>

      <div className="mx-auto flex w-full max-w-xl flex-col gap-4 p-6">
        <Alert>
          <AlertTitle>Not implemented</AlertTitle>
          <AlertDescription>
            Scaffolded from Fractal's <code>account_settings/safety_page/ignored_users_subpage/mod.blp</code>. The widget tree to rebuild is in the
            route file.
          </AlertDescription>
        </Alert>
      </div>
    </div>
  )
}
