# frozen_string_literal: true

# /matrix/login/setup — Session setup
#
# Fractal: login/session_setup_view.{blp,rs}
#
# NOT IMPLEMENTED.
#
# The first screen after a session exists but before it is usable: the device has keys to publish and an identity to verify or bootstrap.
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
# login/session_setup_view.blp
#
#   <Adw.NavigationPage id="SessionSetupView">
#     <Gtk.Stack id="stack" slot="child">
#       <Gtk.StackPage>
#         <Adw.ToolbarView slot="child">
#           <Adw.HeaderBar>
#             <Adw.WindowTitle slot="title-widget" />
#           </Adw.HeaderBar>
#           <Gtk.Box slot="content">
#             <OfflineBanner />
#             <Gtk.Box>
#               <Adw.Spinner />
#               <Gtk.Label />
#             </Gtk.Box>
#           </Gtk.Box>
#         </Adw.ToolbarView>
#       </Gtk.StackPage>
#     </Gtk.Stack>
#   </Adw.NavigationPage>
#

get "/" do
  render("matrix/login/setup")
end

post "/" do
  halt(501, "matrix: not implemented\n")
end

__END__

import { Head, Link } from "@inertiajs/react"
import { ArrowLeft } from "lucide-react"

import { Alert, AlertDescription, AlertTitle } from "@/components/reui/alert"
import { ShellHeader } from "@/components/admin/slots"

export default function MatrixLoginSetup({}: {

}) {
  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title={"Session setup"} />

      <ShellHeader>
        <Link href={"/matrix/login"} className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">Session setup</h1>
      </ShellHeader>

      <div className="mx-auto flex w-full max-w-xl flex-col gap-4 p-6">
        <Alert>
          <AlertTitle>Not implemented</AlertTitle>
          <AlertDescription>
            Scaffolded from Fractal's <code>login/session_setup_view.blp</code>. The widget tree to rebuild is in the
            route file.
          </AlertDescription>
        </Alert>
      </div>
    </div>
  )
}
