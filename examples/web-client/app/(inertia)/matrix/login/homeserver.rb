# frozen_string_literal: true

# /matrix/login/homeserver — Homeserver
#
# Fractal: login/homeserver_page.{blp,rs}
#
# NOT IMPLEMENTED.
#
# Which homeserver to log in to, and what it supports: the well-known lookup and the login flows it advertises decide whether the next screen is a password form or the browser.
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
# login/homeserver_page.blp
#
#   <Adw.NavigationPage id="LoginHomeserverPage">
#     <Adw.ToolbarView slot="child">
#       <Adw.HeaderBar />
#       <Gtk.Box slot="content">
#         <OfflineBanner />
#         <Gtk.ScrolledWindow id="scrolled_window">
#           <Adw.Clamp slot="child">
#             <Gtk.Box slot="child">
#               <Gtk.Label id="title" />
#               <Gtk.Picture />
#               <Gtk.Box>
#                 <Gtk.ListBox>
#                   <Adw.EntryRow id="homeserver_entry" />
#                 </Gtk.ListBox>
#                 <Gtk.Label id="homeserver_help" />
#               </Gtk.Box>
#               <LoadingButton id="next_button" />
#               <Gtk.Button />
#             </Gtk.Box>
#           </Adw.Clamp>
#         </Gtk.ScrolledWindow>
#       </Gtk.Box>
#     </Adw.ToolbarView>
#   </Adw.NavigationPage>
#

get "/" do
  render("matrix/login/homeserver")
end

post "/" do
  halt(501, "matrix: not implemented\n")
end

__END__

import { Head, Link } from "@inertiajs/react"
import { ArrowLeft } from "lucide-react"

import { Alert, AlertDescription, AlertTitle } from "@/components/reui/alert"
import { ShellHeader } from "@/components/admin/slots"

export default function MatrixLoginHomeserver({}: {

}) {
  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title={"Homeserver"} />

      <ShellHeader>
        <Link href={"/matrix/login"} className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">Homeserver</h1>
      </ShellHeader>

      <div className="mx-auto flex w-full max-w-xl flex-col gap-4 p-6">
        <Alert>
          <AlertTitle>Not implemented</AlertTitle>
          <AlertDescription>
            Scaffolded from Fractal's <code>login/homeserver_page.blp</code>. The widget tree to rebuild is in the
            route file.
          </AlertDescription>
        </Alert>
      </div>
    </div>
  )
}
