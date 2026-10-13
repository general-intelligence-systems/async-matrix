# frozen_string_literal: true

# /matrix/rooms/:roomId/media/audio — Audio
#
# Fractal: room_details/history_viewer/audio.{blp,rs}
#
# The room's m.audio messages as a list, with a player per row.
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
# session_view/room_details/history_viewer/audio.blp
#
#   <Adw.NavigationPage id="ContentAudioHistoryViewer">
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
  room = Models::Matrix::Room.first(room_id: params["roomId"]) || halt(404, "matrix: no such room\\n")

  render(
    "matrix/rooms/[roomId]/media/audio",
    roomId:    room.room_id,
    roomTitle: room.title,
    items:     room.events
      .where(type: "m.room.message")
      .order(Sequel.desc(:origin_server_ts))
      .limit(200)
      .all
      .select{|event| ["m.audio"].include?(event.content["msgtype"])}
      .map{|event|
        {
          eventId:  event.event_id,
          body:     event.content["body"],
          media:    Matrix::RoomActions.media_url(event.content["url"]),
          mimetype: event.content.dig("info", "mimetype"),
          size:     event.content.dig("info", "size"),
          sender:   event.sender,
          ts:       event.origin_server_ts.to_i,
        }
      },
  )
end

post "/" do
  act! do
    case params["action"].to_s
    in "redact"
      Matrix::RoomActions.redact(room_id!, params["event_id"].to_s, params["reason"])
    else
      halt(400, "matrix: no such action\n")
    end
  end
end

__END__

import { Head, Link, router } from "@inertiajs/react"
import { ArrowLeft, Trash2 } from "lucide-react"

import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { Empty, EmptyHeader, EmptyTitle } from "@/components/ui/empty"
import { Item, ItemContent, ItemDescription, ItemTitle } from "@/components/ui/item"
import { ScrollArea } from "@/components/ui/scroll-area"
import { ShellHeader } from "@/components/admin/slots"

type Item_ = {
  eventId: string
  body: string | null
  media: string | null
  mimetype: string | null
  size: number | null
  sender: string
  ts: number
}

export default function MatrixRoomMediaAudio({
  roomId,
  roomTitle,
  items,
}: {
  roomId: string
  roomTitle: string
  items: Item_[]
}) {
  const encoded = encodeURIComponent(roomId)

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title={`Audio · ${roomTitle}`} />

      <ShellHeader>
        <Link href={`/matrix/rooms/${encoded}/about`} className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">Audio</h1>
      </ShellHeader>

      <ScrollArea className="min-h-0 flex-1">
        <div className="mx-auto flex w-full max-w-2xl flex-col gap-4 p-6">
          {items.length === 0 ? (
            <Empty className="py-16">
              <EmptyHeader>
                <EmptyTitle>No Audio</EmptyTitle>
              </EmptyHeader>
            </Empty>
          ) : (
            <Card>
              <CardContent className="flex flex-col gap-2 pt-6">
                {items.map((item) => (
                  <Item key={item.eventId}>
                    {item.media && <audio src={item.media} controls className="w-48" />}
                    <ItemContent>
                      <ItemTitle className="truncate">{item.body}</ItemTitle>
                      <ItemDescription>
                        {item.sender} · {new Date(item.ts).toLocaleDateString()}
                        {item.size ? ` · ${Math.ceil(item.size / 1024)} KB` : ""}
                      </ItemDescription>
                    </ItemContent>
                    <Button
                      size="sm"
                      variant="ghost"
                      onClick={() =>
                        router.post(`/matrix/rooms/${encoded}/media/audio`, {
                          action: "redact",
                          event_id: item.eventId,
                        })
                      }
                    >
                      <Trash2 className="size-4" />
                    </Button>
                  </Item>
                ))}
              </CardContent>
            </Card>
          )}
        </div>
      </ScrollArea>
    </div>
  )
}
