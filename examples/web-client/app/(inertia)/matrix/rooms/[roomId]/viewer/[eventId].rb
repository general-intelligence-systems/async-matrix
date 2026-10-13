# frozen_string_literal: true

# /matrix/rooms/:roomId/viewer/:eventId — Media viewer
#
# Fractal: session_view/media_viewer.{blp,rs}
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
  event = Models::Matrix::Event.first(room_id: room.room_id, event_id: params["eventId"]) ||
    halt(404, "matrix: no such event\n")

  render(
    "matrix/rooms/[roomId]/viewer/[eventId]",
    roomId:    room.room_id,
    roomTitle: room.title,
    event:     {
      eventId:  event.event_id,
      body:     event.content["body"],
      msgtype:  event.content["msgtype"],
      media:    Matrix::RoomActions.media_url(event.content["url"]),
      mimetype: event.content.dig("info", "mimetype"),
      sender:   event.sender,
      ts:       event.origin_server_ts.to_i,
    },
  )
end

post "/" do
  act! do
    case params["action"].to_s
    in "redact"
      Matrix::RoomActions.redact(room_id!, params["eventId"].to_s, params["reason"])
    else
      halt(400, "matrix: no such action\n")
    end
  end
end

__END__

import { Head, Link, router } from "@inertiajs/react"
import { ArrowLeft, Download, Trash2 } from "lucide-react"

import { Button } from "@/components/ui/button"
import { ShellHeader } from "@/components/admin/slots"

export default function MatrixRoomViewer({
  roomId,
  roomTitle,
  event,
}: {
  roomId: string
  roomTitle: string
  event: {
    eventId: string
    body: string | null
    msgtype: string | null
    media: string | null
    mimetype: string | null
    sender: string
    ts: number
  }
}) {
  const encoded = encodeURIComponent(roomId)

  return (
    <div className="flex min-h-0 flex-1 flex-col bg-black/95">
      <Head title={`${event.body ?? "Media"} · ${roomTitle}`} />

      <ShellHeader>
        <Link href={`/matrix/rooms/${encoded}`} className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <div className="flex min-w-0 flex-col">
          <span className="truncate text-sm font-medium">{event.body}</span>
          <span className="truncate text-xs text-muted-foreground">
            {event.sender} · {new Date(event.ts).toLocaleString()}
          </span>
        </div>
        {event.media && (
          <Button
            variant="ghost"
            size="sm"
            className="ms-auto"
            nativeButton={false}
            render={<a href={event.media} download={event.body ?? undefined} />}
          >
            <Download className="size-4" />
          </Button>
        )}
        <Button
          variant="ghost"
          size="sm"
          className={event.media ? undefined : "ms-auto"}
          onClick={() =>
            router.post(`/matrix/rooms/${encoded}/viewer/${encodeURIComponent(event.eventId)}`, {
              action: "redact",
            })
          }
        >
          <Trash2 className="size-4" />
        </Button>
      </ShellHeader>

      <div className="flex min-h-0 flex-1 items-center justify-center p-4">
        {event.media && event.msgtype === "m.video" ? (
          <video src={event.media} controls className="max-h-full max-w-full" />
        ) : event.media ? (
          <img src={event.media} alt={event.body ?? ""} className="max-h-full max-w-full object-contain" />
        ) : (
          <p className="text-sm text-muted-foreground">This event carries no media.</p>
        )}
      </div>
    </div>
  )
}
