# frozen_string_literal: true

# /matrix/login/method — Log in method
#
# Fractal: login/method_page.{blp,rs}
#
# NOT IMPLEMENTED.
#
# The login flows the homeserver advertises, as a choice: a password form when it supports m.login.password, the browser when it is OIDC.
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
# login/method_page.blp
#
#   <Adw.NavigationPage id="LoginMethodPage">
#     <Adw.ToolbarView slot="child">
#       <Adw.HeaderBar />
#       <Gtk.Box slot="content">
#         <OfflineBanner />
#         <Gtk.ScrolledWindow id="scrolled_window">
#           <Adw.Clamp slot="child">
#             <Gtk.Box slot="child">
#               <Gtk.Box>
#                 <Gtk.Label id="title" />
#                 <Gtk.Box>
#                   <Gtk.Image />
#                   <Gtk.Label id="homeserver_url" />
#                 </Gtk.Box>
#               </Gtk.Box>
#               <Gtk.ListBox>
#                 <Adw.EntryRow id="username_entry" />
#               </Gtk.ListBox>
#               <Gtk.ListBox>
#                 <Adw.PasswordEntryRow id="password_entry" />
#               </Gtk.ListBox>
#               <Gtk.Button id="sso_button" />
#               <LoadingButton id="next_button" />
#             </Gtk.Box>
#           </Adw.Clamp>
#         </Gtk.ScrolledWindow>
#       </Gtk.Box>
#     </Adw.ToolbarView>
#   </Adw.NavigationPage>
#

get "/" do
  render("matrix/login/method")
end

post "/" do
  halt(501, "matrix: not implemented\n")
end

__END__

import { Head, Link } from "@inertiajs/react"
import { ArrowLeft } from "lucide-react"

import { Alert, AlertDescription, AlertTitle } from "@/components/reui/alert"
import { ShellHeader } from "@/components/admin/slots"

export default function MatrixLoginMethod({}: {

}) {
  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title={"Log in method"} />

      <ShellHeader>
        <Link href={"/matrix/login"} className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">Log in method</h1>
      </ShellHeader>

      <div className="mx-auto flex w-full max-w-xl flex-col gap-4 p-6">
        <Alert>
          <AlertTitle>Not implemented</AlertTitle>
          <AlertDescription>
            Scaffolded from Fractal's <code>login/method_page.blp</code>. The widget tree to rebuild is in the
            route file.
          </AlertDescription>
        </Alert>
      </div>
    </div>
  )
}
