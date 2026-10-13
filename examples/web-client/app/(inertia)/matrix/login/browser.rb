# frozen_string_literal: true

# /matrix/login/browser — Log in with browser
#
# Fractal: login/in_browser_page.{blp,rs}
#
# NOT IMPLEMENTED.
#
# The holding screen while the OIDC flow runs elsewhere. Fractal opens a browser and waits on a loopback server; here the browser is already the client, so this is where the redirect to MAS is taken.
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
# login/in_browser_page.blp
#
#   <Adw.NavigationPage id="LoginInBrowserPage">
#     <Adw.ToolbarView slot="child">
#       <Adw.HeaderBar />
#       <Gtk.Box slot="content">
#         <OfflineBanner />
#         <Gtk.ScrolledWindow id="scrolled_window">
#           <Adw.Clamp slot="child">
#             <Gtk.Box slot="child">
#               <Gtk.Label id="title" />
#               <Gtk.Label id="instructions" />
#               <Gtk.Button id="continue_btn">
#                 <Gtk.Box slot="child">
#                   <Gtk.Label />
#                   <Gtk.Image />
#                 </Gtk.Box>
#               </Gtk.Button>
#             </Gtk.Box>
#           </Adw.Clamp>
#         </Gtk.ScrolledWindow>
#       </Gtk.Box>
#     </Adw.ToolbarView>
#   </Adw.NavigationPage>
#

get "/" do
  render("matrix/login/browser")
end

post "/" do
  halt(501, "matrix: not implemented\n")
end

__END__

import { Head, Link } from "@inertiajs/react"
import { ArrowLeft } from "lucide-react"

import { Alert, AlertDescription, AlertTitle } from "@/components/reui/alert"
import { ShellHeader } from "@/components/admin/slots"

export default function MatrixLoginBrowser({}: {

}) {
  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title={"Log in with browser"} />

      <ShellHeader>
        <Link href={"/matrix/login"} className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">Log in with browser</h1>
      </ShellHeader>

      <div className="mx-auto flex w-full max-w-xl flex-col gap-4 p-6">
        <Alert>
          <AlertTitle>Not implemented</AlertTitle>
          <AlertDescription>
            Scaffolded from Fractal's <code>login/in_browser_page.blp</code>. The widget tree to rebuild is in the
            route file.
          </AlertDescription>
        </Alert>
      </div>
    </div>
  )
}
