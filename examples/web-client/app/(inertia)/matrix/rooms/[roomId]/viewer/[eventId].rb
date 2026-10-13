# frozen_string_literal: true

# /matrix/rooms/:roomId/viewer/:eventId — Media viewer
#
# Fractal: session_view/media_viewer.{blp,rs}
#
# NOT IMPLEMENTED.
#
# One image or video at full size, reached from the timeline or from a history viewer.
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
# session_view/media_viewer.blp
#
#   <Gtk.Widget id="MediaViewer">
#     <Adw.ToolbarView id="toolbar_view">
#       <Gtk.HeaderBar id="header_bar">
#         <Gtk.Label slot="title-widget" />
#         <Gtk.Button id="back" />
#         <Gtk.MenuButton id="menu" />
#         <Gtk.Button />
#         <Gtk.Button />
#       </Gtk.HeaderBar>
#       <ScaleRevealer id="revealer" slot="content">
#         <MediaContentViewer id="media" slot="child">
#           <Gtk.PopoverMenu slot="popover" />
#         </MediaContentViewer>
#       </ScaleRevealer>
#     </Adw.ToolbarView>
#     <Gtk.EventControllerMotion />
#     <Gtk.GestureClick />
#   </Gtk.Widget>
#

get "/" do
  room = Models::Matrix::Room.first(room_id: params["roomId"]) || halt(404, "matrix: no such room\n")
  render(
    "matrix/rooms/[roomId]/viewer/[eventId]",
    roomId:    room.room_id,
    roomTitle: room.title,
    eventId:   params["eventId"],
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

export default function MatrixRoomsRoomidViewerEventid({roomId, roomTitle, eventId}: {
  roomId: string
  roomTitle: string
  eventId: string
}) {
  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title={`Media viewer · ${roomTitle}`} />

      <ShellHeader>
        <Link href={`/matrix/rooms/${encodeURIComponent(roomId)}/about`} className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">Media viewer</h1>
      </ShellHeader>

      <div className="mx-auto flex w-full max-w-xl flex-col gap-4 p-6">
        <Alert>
          <AlertTitle>Not implemented</AlertTitle>
          <AlertDescription>
            Scaffolded from Fractal's <code>session_view/media_viewer.blp</code>. The widget tree to rebuild is in the
            route file.
          </AlertDescription>
        </Alert>
      </div>
    </div>
  )
}
