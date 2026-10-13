# frozen_string_literal: true

# /matrix/error — Error
#
# Fractal: error_page.{blp,rs}
#
# The window state Fractal shows when a session exists but cannot be opened. Here it is a page the layout redirects to, since Expo has no +error convention.
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
# error_page.blp
#
#   <Adw.Bin id="ErrorPage">
#     <Adw.ToolbarView>
#       <Adw.HeaderBar>
#         <Adw.WindowTitle slot="title-widget" />
#         <AccountSwitcherButton id="account_switcher" />
#         <Gtk.Button />
#         <Gtk.Button />
#       </Adw.HeaderBar>
#       <Gtk.Stack id="stack" slot="content">
#         <Gtk.StackPage>
#           <Adw.StatusPage id="secret_error_page" slot="child">
#             <Adw.Clamp id="linux_secret_instructions">
#               <Gtk.Box>
#                 <Gtk.Label />
#                 <Gtk.Box>
#                   <Gtk.Label />
#                   <Gtk.Box>
#                     <Gtk.Label />
#                     <Gtk.Label />
#                   </Gtk.Box>
#                   <Gtk.Box>
#                     <Gtk.Label />
#                     <Gtk.Box>
#                       <Gtk.Label />
#                       <Gtk.Box>
#                         <Gtk.ScrolledWindow>
#                           <Gtk.Label id="secret_service_override_command" slot="child" />
#                         </Gtk.ScrolledWindow>
#                         <Gtk.Button />
#                       </Gtk.Box>
#                     </Gtk.Box>
#                   </Gtk.Box>
#                   <Gtk.Box>
#                     <Gtk.Label />
#                     <Gtk.Label />
#                   </Gtk.Box>
#                 </Gtk.Box>
#                 <Gtk.Label />
#               </Gtk.Box>
#             </Adw.Clamp>
#           </Adw.StatusPage>
#         </Gtk.StackPage>
#         <Gtk.StackPage>
#           <Adw.StatusPage id="session_error_page" slot="child" />
#         </Gtk.StackPage>
#       </Gtk.Stack>
#     </Adw.ToolbarView>
#   </Adw.Bin>
#

get "/" do
  render(
    "matrix/error",
    message: session.delete(:matrix_error),
  )
end

post "/" do
  case params["action"].to_s
  in "dismiss"
    session.delete(:matrix_error)
    redirect("/matrix", 303)
  in "sign_out"
    credential = Models::Matrix::Credential.first

    unless credential.nil?
      Matrix::Session.forget!(credential)
    end

    session.delete(:matrix_error)
    redirect("/matrix/login", 303)
  else
    halt(400, "matrix: no such action\n")
  end
end

__END__

import { Form, Head } from "@inertiajs/react"
import { TriangleAlert } from "lucide-react"

import { Button } from "@/components/ui/button"
import { Empty, EmptyDescription, EmptyHeader, EmptyMedia, EmptyTitle } from "@/components/ui/empty"

export default function MatrixError({ message }: { message: string | null }) {
  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title="Error" />

      <Empty className="flex-1">
        <EmptyHeader>
          <EmptyMedia variant="icon">
            <TriangleAlert className="size-6" />
          </EmptyMedia>
          <EmptyTitle>Error</EmptyTitle>
          <EmptyDescription>
            {message ?? "The session could not be opened. Check your network connection."}
          </EmptyDescription>
        </EmptyHeader>

        <div className="flex gap-2">
          <Form action="/matrix/error" method="post">
            {({ processing }) => (
              <>
                <input type="hidden" name="action" value="dismiss" />
                <Button type="submit" disabled={processing}>
                  Try Again
                </Button>
              </>
            )}
          </Form>
          <Form action="/matrix/error" method="post">
            {({ processing }) => (
              <>
                <input type="hidden" name="action" value="sign_out" />
                <Button type="submit" variant="outline" disabled={processing}>
                  Log in again
                </Button>
              </>
            )}
          </Form>
        </div>
      </Empty>
    </div>
  )
}
