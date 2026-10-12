# frozen_string_literal: true

# /matrix/rooms/:roomId/threads/:threadId — Thread
#
# Fractal: nothing -- see threads.rb
#
# NOT IMPLEMENTED.
#
# One thread's timeline. Its own chunk list: matrix_timeline_chunks keys on
# (room_id, thread_root_id), so a thread paginates independently of the main
# timeline exactly as the SDK's LinkedChunkId::Thread does.
# ── No Fractal widget tree ─────────────────────────────────────────────────
#
# Fractal has no thread UI at all, so there is nothing to catalog here. The
# nearest structure to borrow is the room timeline's -- see
# rooms/[roomId].rb, whose tree is the one this should echo.
#
# ── Build with ─────────────────────────────────────────────────────────────
#
# @reui/ai-chat-9 — "Branching AI chat thread with reply versions, cited sources and
#   code artifacts". It holds the transcript as a TREE with a fork rail, which is the
#   only block in the catalog that models a thread as anything but a flat list.
#
#   (no Fractal equivalent)  ->  the fork rail, reused as the thread-root rail
#   root event               ->  ui/bubble, pinned at the top
#   replies                  ->  same message components as rooms/[roomId].rb
#   subscribe                ->  ui/switch -> matrix_thread_subscriptions
#
# One thread. Its own chunk list in the schema, so it paginates independently
# of the main timeline -- same as the SDK's LinkedChunkId::Thread.
get "/" do
  room = matrix_room!
  thread_id = params["threadId"].to_s

  root = Models::Matrix::Event.first(
    user_id: matrix_user_id, room_id: room[:room_id], event_id: thread_id,
  ) || halt(404, "matrix: no such thread\n")

  replies = Models::Matrix::Event
    .where(user_id: matrix_user_id, room_id: room[:room_id], thread_root_id: thread_id)
    .exclude(type: "m.reaction")
    .order(:origin_server_ts)
    .all

  subscription = DB[:matrix_thread_subscriptions].first(
    user_id: matrix_user_id, room_id: room[:room_id], event_id: thread_id,
  )

  render(
    "matrix/rooms/[roomId]/threads/[threadId]",
    roomId:     room[:room_id],
    roomTitle:  matrix_room_title(room),
    threadId:   thread_id,
    root:       matrix_event_json(root, []),
    replies:    replies.map { |event| matrix_event_json(event, []) },
    subscribed: subscription && subscription[:status] == "subscribed",
    selfId:     Models::Matrix::Credential.first&.matrix_user_id.to_s,
  )
end

__END__

import { Head, Link } from "@inertiajs/react"
import { ArrowLeft, Send } from "lucide-react"

import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Label } from "@/components/ui/label"
import {
  InputGroup,
  InputGroupAddon,
  InputGroupButton,
  InputGroupTextarea,
} from "@/components/ui/input-group"
import { Message, MessageAvatar, MessageContent, MessageFooter, MessageHeader } from "@/components/ui/message"
import { ScrollArea } from "@/components/ui/scroll-area"
import { Switch } from "@/components/ui/switch"
import { cn } from "cn"
import { ShellHeader } from "@/components/admin/slots"

type Event = {
  eventId: string
  sender: string
  senderName: string
  senderAvatar: string | null
  body: string | null
  formatted: string | null
  ts: number
  edited: boolean
  redacted: boolean
}

const initial = (name: string) => name.replace(/^[#!@]/, "").charAt(0).toUpperCase()
const time = (ts: number) =>
  new Date(ts).toLocaleTimeString(undefined, { hour: "2-digit", minute: "2-digit" })

function ThreadMessage({ event, own }: { event: Event; own: boolean }) {
  return (
    <Message align={own ? "end" : "start"}>
      <MessageAvatar>
        <Avatar className="size-8">
          {event.senderAvatar && <AvatarImage src={event.senderAvatar} alt="" />}
          <AvatarFallback className="text-[11px]">{initial(event.senderName)}</AvatarFallback>
        </Avatar>
      </MessageAvatar>
      <MessageContent>
        <MessageHeader>
          <span className="font-medium text-foreground">{event.senderName}</span>
        </MessageHeader>
        <div
          className={cn(
            "w-fit max-w-prose rounded-lg px-3 py-1.5 text-sm",
            own ? "bg-primary text-primary-foreground" : "bg-muted",
            event.redacted && "italic opacity-60"
          )}
        >
          {event.redacted ? "Message deleted" : event.body}
        </div>
        <MessageFooter>
          <span className="tabular-nums">{time(event.ts)}</span>
          {event.edited && <span className="ml-1">(edited)</span>}
        </MessageFooter>
      </MessageContent>
    </Message>
  )
}

export default function MatrixRoomThread({
  roomId,
  roomTitle,
  root,
  replies,
  subscribed,
  selfId,
}: {
  roomId: string
  roomTitle: string
  threadId: string
  root: Event
  replies: Event[]
  subscribed: boolean
  selfId: string
}) {
  const encoded = encodeURIComponent(roomId)

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title={`Thread · ${roomTitle}`} />

      <ShellHeader>
        <Link href={`/matrix/rooms/${encoded}/threads`} className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">Thread</h1>
        <div className="ms-auto flex items-center gap-2">
          <Label htmlFor="subscribed" className="text-xs font-normal text-muted-foreground">
            Follow
          </Label>
          <Switch id="subscribed" defaultChecked={subscribed} />
        </div>
      </ShellHeader>

      <ScrollArea className="min-h-0 flex-1">
        <div className="mx-auto flex w-full max-w-3xl flex-col gap-3 p-4">
          {/* The root sits apart from its replies -- it is the subject, not the
              first message of a run. */}
          <div className="rounded-lg border bg-muted/30 p-3">
            <ThreadMessage event={root} own={root.sender === selfId} />
          </div>

          <div className="flex items-center gap-2 px-1 text-xs text-muted-foreground">
            <span>
              {replies.length} {replies.length === 1 ? "reply" : "replies"}
            </span>
            <div className="h-px flex-1 bg-border" />
          </div>

          <div className="flex flex-col gap-1">
            {replies.map((event) => (
              <ThreadMessage key={event.eventId} event={event} own={event.sender === selfId} />
            ))}
          </div>
        </div>
      </ScrollArea>

      <div className="shrink-0 border-t p-3">
        <InputGroup className="mx-auto max-w-3xl">
          <InputGroupTextarea placeholder="Reply in thread" rows={1} className="max-h-40" />
          <InputGroupAddon align="block-end">
            <InputGroupButton size="icon-xs" className="ms-auto" aria-label="Send">
              <Send className="size-4" />
            </InputGroupButton>
          </InputGroupAddon>
        </InputGroup>
      </div>
    </div>
  )
}
