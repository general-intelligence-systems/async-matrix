# frozen_string_literal: true


MSGTYPES = {
  "media" => %w[m.image m.video],
  "files" => %w[m.file],
  "audio" => %w[m.audio],
}.freeze

MSGTYPES = {
  "media" => %w[m.image m.video],
  "files" => %w[m.file],
  "audio" => %w[m.audio],
}.freeze

get "/" do
  room = Models::Matrix::Room.first(room_id: params["roomId"]) || halt(404, "matrix: no such room\n")

  if MSGTYPES.key?(params["kind"])
    kind = params["kind"]
  else
    kind = "media"
  end

  items = room.events
    .where(type: "m.room.message", redacted: false)
    .reverse(:origin_server_ts)
    .limit(200)
    .all
    .select{|event| MSGTYPES.fetch(kind).include?(event.content["msgtype"])}
    .map do |event|
      {
        eventId:  event.event_id,
        body:     event.content["body"],
        msgtype:  event.content["msgtype"],
        sender:   event.sender_name,
        ts:       event.origin_server_ts.to_i,
        size:     event.content.dig("info", "size"),
        mimetype: event.content.dig("info", "mimetype"),
      }
    end

  render(
    "matrix/rooms/[roomId]/media",
    roomId: room.room_id, roomTitle: room.title, kind: kind, items: items,
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
