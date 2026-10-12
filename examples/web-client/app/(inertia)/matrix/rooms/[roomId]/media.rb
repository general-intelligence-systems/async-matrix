# frozen_string_literal: true

# /matrix/rooms/:roomId/media — Media
#
# Fractal: room_details/history_viewer/
#
# NOT IMPLEMENTED.
#
# Everything this room has sent that is a file: ?kind=media|files|audio for
# Fractal's three history-viewer tabs.
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
# session_view/room_details/history_viewer/visual_media.blp
#
#   <Adw.NavigationPage id="ContentVisualMediaHistoryViewer">
#     <Gtk.Overlay>
#       <MediaViewer id="media_viewer" />
#       <Adw.ToolbarView>
#         <Adw.HeaderBar />
#         <Gtk.Stack slot="content" id="stack">
#           <Gtk.StackPage>
#             <Adw.Spinner slot="child" />
#           </Gtk.StackPage>
#           <Gtk.StackPage>
#             <Adw.StatusPage slot="child" />
#           </Gtk.StackPage>
#           <Gtk.StackPage>
#             <Adw.StatusPage slot="child">
#               <Gtk.Button slot="child" />
#             </Adw.StatusPage>
#           </Gtk.StackPage>
#           <Gtk.StackPage>
#             <Gtk.ScrolledWindow slot="child">
#               <Adw.ClampScrollable>
#                 <Gtk.GridView id="grid_view" />
#               </Adw.ClampScrollable>
#             </Gtk.ScrolledWindow>
#           </Gtk.StackPage>
#         </Gtk.Stack>
#       </Adw.ToolbarView>
#     </Gtk.Overlay>
#   </Adw.NavigationPage>
#
# session_view/room_details/history_viewer/visual_media_item.blp
#
#   <Gtk.Widget id="ContentVisualMediaHistoryViewerItem">
#     <Gtk.GestureClick />
#     <Gtk.Overlay id="overlay">
#       <Gtk.Picture id="picture" />
#       <Gtk.Image id="play_icon" />
#     </Gtk.Overlay>
#   </Gtk.Widget>
#
# session_view/room_details/history_viewer/file.blp
#
#   <Adw.NavigationPage id="ContentFileHistoryViewer">
#     <Adw.ToolbarView>
#       <Adw.HeaderBar />
#       <Gtk.Stack slot="content" id="stack">
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
# session_view/room_details/history_viewer/file_row.blp
#
#   <Adw.Bin id="ContentFileHistoryViewerRow">
#     <Gtk.Box>
#       <Gtk.Button id="button" />
#       <Gtk.Box>
#         <Gtk.Label id="title_label" />
#         <Gtk.Label id="size_label" />
#       </Gtk.Box>
#     </Gtk.Box>
#   </Adw.Bin>
#
# session_view/room_details/history_viewer/audio.blp
#
#   <Adw.NavigationPage id="ContentAudioHistoryViewer">
#     <Adw.ToolbarView>
#       <Adw.HeaderBar />
#       <Gtk.Stack slot="content" id="stack">
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
# session_view/room_details/history_viewer/audio_row.blp
#
#   <Adw.Bin id="ContentAudioHistoryViewerRow">
#     <AudioPlayer slot="child" id="player" />
#   </Adw.Bin>
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
#       <ScaleRevealer slot="content" id="revealer">
#         <MediaContentViewer slot="child" id="media">
#           <Gtk.PopoverMenu slot="popover" />
#         </MediaContentViewer>
#       </ScaleRevealer>
#     </Adw.ToolbarView>
#     <Gtk.EventControllerMotion />
#     <Gtk.GestureClick />
#   </Gtk.Widget>
#
# components/media/content_viewer.blp
#
#   <ContextMenuBin id="MediaContentViewer">
#     <Gtk.Stack slot="child" id="stack">
#       <Gtk.StackPage>
#         <Adw.Spinner slot="child" />
#       </Gtk.StackPage>
#       <Gtk.StackPage>
#         <Adw.Bin slot="child" id="viewer" />
#       </Gtk.StackPage>
#       <Gtk.StackPage>
#         <Adw.StatusPage slot="child" id="fallback" />
#       </Gtk.StackPage>
#     </Gtk.Stack>
#   </ContextMenuBin>
#
# ── Build with ─────────────────────────────────────────────────────────────
#
# @reui/solution-files-1 — "Drive Explorer with Folder Tree Rail and Switchable List or
#   Grid Views". The switchable list/grid IS Fractal's three history-viewer tabs: visual
#   media wants a grid, files and audio want a list.
#
#   VisualMedia + Item (grid)    ->  grid of ui/card with aspect-ratio
#   File + FileRow (list)        ->  ui/item rows
#   Audio + AudioRow (list)      ->  ui/item + an audio player, which has no catalog equivalent
#   MediaViewer / ContentViewer  ->  ui/dialog full-bleed + ui/carousel to page between items
#   Gtk.ScrolledWindow paging    ->  ui/scroll-area + back-pagination over the same gap machinery
#
# INSTALL, plain shadcn: carousel, aspect-ratio
#
# NO CATALOG MATCH, hand-build:
#   The audio player. Fractal has a real one (waveform, scrub); the catalog has none.
#
# The history viewer: everything in this room that carries a file.
get "/" do
  room = matrix_room!
  kind = %w[media files audio].include?(params["kind"]) ? params["kind"] : "media"

  msgtypes = {
    "media" => %w[m.image m.video],
    "files" => %w[m.file],
    "audio" => %w[m.audio],
  }.fetch(kind)

  items = Models::Matrix::Event
    .where(room_id: room[:room_id], type: "m.room.message")
    .exclude(redacted: true)
    .reverse(:origin_server_ts)
    .limit(200)
    .all
    .select { |event| msgtypes.include?(event[:content].to_h["msgtype"]) }
    .map do |event|
      content = event[:content].to_h
      info = content["info"].to_h

      {
        eventId:  event[:event_id],
        body:     content["body"],
        msgtype:  content["msgtype"],
        sender:   event[:sender_display_name].to_s.empty? ? event[:sender] : event[:sender_display_name],
        ts:       event[:origin_server_ts].to_i,
        size:     info["size"],
        mimetype: info["mimetype"],
      }
    end

  render(
    "matrix/rooms/[roomId]/media",
    roomId: room[:room_id], roomTitle: matrix_room_title(room), kind: kind, items: items,
  )
end

__END__

import { Head, Link, router } from "@inertiajs/react"
import { ArrowLeft, FileAudio, FileText, ImageIcon } from "lucide-react"

import { Empty, EmptyDescription, EmptyHeader, EmptyTitle } from "@/components/ui/empty"
import { Item, ItemContent, ItemDescription, ItemMedia, ItemTitle } from "@/components/ui/item"
import { ScrollArea } from "@/components/ui/scroll-area"
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { ShellHeader } from "@/components/admin/slots"

type MediaItem = {
  eventId: string
  body: string | null
  msgtype: string
  sender: string
  ts: number
  size: number | null
  mimetype: string | null
}

const KINDS = [
  { value: "media", label: "Media" },
  { value: "files", label: "Files" },
  { value: "audio", label: "Audio" },
]

const bytes = (size: number | null) => {
  if (!size) return null
  const units = ["B", "KB", "MB", "GB"]
  let value = size
  let unit = 0
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024
    unit += 1
  }
  return `${value.toFixed(unit === 0 ? 0 : 1)} ${units[unit]}`
}

export default function MatrixRoomMedia({
  roomId,
  roomTitle,
  kind,
  items,
}: {
  roomId: string
  roomTitle: string
  kind: string
  items: MediaItem[]
}) {
  const encoded = encodeURIComponent(roomId)
  const Icon = kind === "audio" ? FileAudio : kind === "files" ? FileText : ImageIcon

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title={`Media · ${roomTitle}`} />

      <ShellHeader>
        <Link href={`/matrix/rooms/${encoded}/about`} className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">Media</h1>
      </ShellHeader>

      <div className="border-b px-4 py-2">
        <Tabs
          value={kind}
          onValueChange={(value) =>
            router.get(`/matrix/rooms/${encoded}/media`, { kind: value }, { preserveState: false })
          }
        >
          <TabsList>
            {KINDS.map((option) => (
              <TabsTrigger key={option.value} value={option.value}>
                {option.label}
              </TabsTrigger>
            ))}
          </TabsList>
        </Tabs>
      </div>

      <ScrollArea className="min-h-0 flex-1">
        <div className="mx-auto w-full max-w-4xl p-4">
          {items.length === 0 ? (
            <Empty className="py-12">
              <EmptyHeader>
                <EmptyTitle>Nothing here</EmptyTitle>
                <EmptyDescription>No {kind} has been sent to this room.</EmptyDescription>
              </EmptyHeader>
            </Empty>
          ) : kind === "media" ? (
            // Visual media wants a grid; files and audio want a list. That is
            // the whole reason Fractal splits the history viewer in three.
            <div className="grid grid-cols-2 gap-2 sm:grid-cols-3 md:grid-cols-4">
              {items.map((item) => (
                <div
                  key={item.eventId}
                  className="flex aspect-square flex-col items-center justify-center gap-1 rounded-md border bg-muted/40 p-2 text-center"
                >
                  <Icon className="size-6 text-muted-foreground" />
                  <span className="line-clamp-2 text-xs">{item.body}</span>
                </div>
              ))}
            </div>
          ) : (
            <div className="flex flex-col gap-1">
              {items.map((item) => (
                <Item key={item.eventId}>
                  <ItemMedia variant="icon">
                    <Icon className="size-4" />
                  </ItemMedia>
                  <ItemContent>
                    <ItemTitle>{item.body}</ItemTitle>
                    <ItemDescription>
                      {item.sender}
                      {bytes(item.size) ? ` · ${bytes(item.size)}` : ""}
                      {` · ${new Date(item.ts).toLocaleDateString()}`}
                    </ItemDescription>
                  </ItemContent>
                </Item>
              ))}
            </div>
          )}
        </div>
      </ScrollArea>
    </div>
  )
}
