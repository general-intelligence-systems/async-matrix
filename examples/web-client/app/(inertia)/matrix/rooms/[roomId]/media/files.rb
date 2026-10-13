# frozen_string_literal: true

# /matrix/rooms/:roomId/media/files — Files
#
# Fractal: room_details/history_viewer/file.{blp,rs}
#
# NOT IMPLEMENTED.
#
# The room's m.file messages as a list. Fractal keeps three history viewers, one per kind; /media is the visual one.
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
# session_view/room_details/history_viewer/file.blp
#
#   <Adw.NavigationPage id="ContentFileHistoryViewer">
#     <Adw.ToolbarView>
#       <Adw.HeaderBar />
#       <Gtk.Stack id="stack" slot="content">
#         <Gtk.StackPage>
#           <Adw.Spinner slot="child" />
#         </Gtk.StackPage>
#         <Gtk.StackPage>
#           <Adw.StatusPage slot="child" />
#         </Gtk.StackPage>
#         <Gtk.StackPage>
#           <Adw.StatusPage slot="child">
#             <Gtk.Button slot="child" />
#           </Adw.StatusPage>
#         </Gtk.StackPage>
#         <Gtk.StackPage>
#           <Gtk.ScrolledWindow slot="child">
#             <Adw.ClampScrollable>
#               <Gtk.ListView id="list_view" />
#             </Adw.ClampScrollable>
#           </Gtk.ScrolledWindow>
#         </Gtk.StackPage>
#       </Gtk.Stack>
#     </Adw.ToolbarView>
#   </Adw.NavigationPage>
#

get "/" do
  room = Models::Matrix::Room.first(room_id: params["roomId"]) || halt(404, "matrix: no such room\n")
  render(
    "matrix/rooms/[roomId]/media/files",
    roomId:    room.room_id,
    roomTitle: room.title,
  )
end

post "/" do
  halt(501, "matrix: not implemented\n")
end

__END__

import { Head, Link } from "@inertiajs/react"
import { ArrowLeft } from "lucide-react"

import { Alert, AlertDescription, AlertTitle } from "@/components/reui/alert"
import { ShellHeader } from "@/components/admin/slots"

export default function MatrixRoomsRoomidMediaFiles({roomId, roomTitle}: {
  roomId: string
  roomTitle: string
}) {
  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title={`Files · ${roomTitle}`} />

      <ShellHeader>
        <Link href={`/matrix/rooms/${encodeURIComponent(roomId)}/about`} className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">Files</h1>
      </ShellHeader>

      <div className="mx-auto flex w-full max-w-xl flex-col gap-4 p-6">
        <Alert>
          <AlertTitle>Not implemented</AlertTitle>
          <AlertDescription>
            Scaffolded from Fractal's <code>session_view/room_details/history_viewer/file.blp</code>. The widget tree to rebuild is in the
            route file.
          </AlertDescription>
        </Alert>
      </div>
    </div>
  )
}
