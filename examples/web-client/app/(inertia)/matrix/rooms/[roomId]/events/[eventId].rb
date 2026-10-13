# frozen_string_literal: true


get "/" do
  room = Models::Matrix::Room.first(room_id: params["roomId"]) || halt(404, "matrix: no such room\n")
  event = room.events.first(event_id: params["eventId"].to_s) ||
    halt(404, "matrix: no such event\n")

  render(
    "matrix/rooms/[roomId]/events/[eventId]",
    roomId:    room.room_id,
    roomTitle: room.title,
    event:     {
      eventId:         event.event_id,
      type:            event.type,
      sender:          event.sender,
      senderName:      event.sender_name,
      senderAvatar:    event.sender_avatar_url,
      body:            event.content["body"],
      ts:              event.origin_server_ts.to_i,
      edited:          event.edited?,
      redacted:        event.redacted?,
      decryptionError: event.decryption_error,
      stateKey:        event.state_key,
    },
    source:    MultiJson.dump(event.raw || event.content, pretty: true),
    unsigned:  MultiJson.dump(event.unsigned, pretty: true),
  )
end

__END__

import { Head, Link } from "@inertiajs/react"
import { ArrowLeft } from "lucide-react"

import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Badge } from "@/components/reui/badge"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { ScrollArea } from "@/components/ui/scroll-area"
import { ShellHeader } from "@/components/admin/slots"

type Event = {
  eventId: string
  type: string
  sender: string
  senderName: string
  senderAvatar: string | null
  body: string | null
  ts: number
  edited: boolean
  redacted: boolean
  decryptionError: string | null
  stateKey: string | null
}

const initial = (name: string) => name.replace(/^[#!@]/, "").charAt(0).toUpperCase()

function Field({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-baseline justify-between gap-4 py-1">
      <span className="shrink-0 text-xs text-muted-foreground">{label}</span>
      <code className="truncate font-mono text-xs">{value}</code>
    </div>
  )
}

export default function MatrixEvent({
  roomId,
  roomTitle,
  event,
  source,
  unsigned,
}: {
  roomId: string
  roomTitle: string
  event: Event
  source: string
  unsigned: string
}) {
  const encoded = encodeURIComponent(roomId)

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title={`Event · ${roomTitle}`} />

      <ShellHeader>
        <Link href={`/matrix/rooms/${encoded}`} className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">Event</h1>
        <Badge variant="secondary" size="sm" className="ms-auto font-mono">
          {event.type}
        </Badge>
      </ShellHeader>

      <ScrollArea className="min-h-0 flex-1">
        <div className="mx-auto flex w-full max-w-3xl flex-col gap-4 p-6">
          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Event</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="mb-3 flex items-center gap-2">
                <Avatar className="size-8">
                  {event.senderAvatar && <AvatarImage src={event.senderAvatar} alt="" />}
                  <AvatarFallback className="text-[11px]">
                    {initial(event.senderName)}
                  </AvatarFallback>
                </Avatar>
                <div className="flex min-w-0 flex-col">
                  <span className="truncate text-sm font-medium">{event.senderName}</span>
                  <span className="truncate font-mono text-xs text-muted-foreground">
                    {event.sender}
                  </span>
                </div>
              </div>

              {event.body && (
                <p className="mb-3 rounded-md bg-muted px-3 py-2 text-sm whitespace-pre-wrap">
                  {event.body}
                </p>
              )}

              <Field label="Event ID" value={event.eventId} />
              <Field label="Room" value={roomId} />
              <Field label="Timestamp" value={new Date(event.ts).toLocaleString()} />
              {event.stateKey !== null && <Field label="State key" value={event.stateKey || '""'} />}
              {event.edited && <Field label="Edited" value="yes" />}
              {event.redacted && <Field label="Redacted" value="yes" />}
              {event.decryptionError && (
                <Field label="Decryption error" value={event.decryptionError} />
              )}
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Source</CardTitle>
            </CardHeader>
            <CardContent>
              <pre className="max-h-96 overflow-auto rounded-md bg-muted p-3 font-mono text-xs">
                {source}
              </pre>
            </CardContent>
          </Card>

          {unsigned !== "{}" && (
            <Card>
              <CardHeader>
                <CardTitle className="text-sm">Unsigned</CardTitle>
              </CardHeader>
              <CardContent>
                <pre className="max-h-64 overflow-auto rounded-md bg-muted p-3 font-mono text-xs">
                  {unsigned}
                </pre>
              </CardContent>
            </Card>
          )}
        </div>
      </ScrollArea>
    </div>
  )
}
