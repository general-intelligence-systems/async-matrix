# frozen_string_literal: true


get "/" do
  room = Models::Matrix::Room.first(room_id: params["roomId"]) || halt(404, "matrix: no such room\n")
  me = Models::Matrix::Credential.first&.matrix_user_id.to_s

  render(
    "matrix/rooms/[roomId]",
    room:   {
      roomId:      room.room_id,
      title:       room.title,
      avatarUrl:   room.avatar_url,
      topic:       room.topic,
      encrypted:   room.encrypted,
      direct:      room.direct,
      membership:  room.membership,
      memberCount: room.joined_member_count.to_i,
      invitedBy:   Models::Matrix::RoomState.first(
        room_id: room.room_id, event_type: "m.room.member", state_key: me,
      )&.sender,
    },
    events: room.events.main_timeline.chronological.limit(200).all.map{|event|
      {
        eventId:         event.event_id,
        type:            event.type,
        sender:          event.sender,
        senderName:      event.sender_name,
        senderAvatar:    event.sender_avatar_url,
        body:            event.content["body"],
        formatted:       event.formatted_body,
        ts:              event.origin_server_ts.to_i,
        edited:          event.edited?,
        redacted:        event.redacted?,
        decryptionError: event.decryption_error,
        stateKey:        event.state_key,
        replyToId:       event.reply_to_id,
        reactions:       event.reactions(me),
      }
    },
    selfId: me,
  )
end

post "/" do
  halt(501, "matrix: not implemented\n")
end

__END__

import { Head, Link } from "@inertiajs/react"
import {
  ArrowLeft,
  Lock,
  Paperclip,
  Send,
  Settings2,
  ShieldAlert,
  Users,
} from "lucide-react"

import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Badge } from "@/components/reui/badge"
import { Button } from "@/components/ui/button"
import { Empty, EmptyDescription, EmptyHeader, EmptyMedia, EmptyTitle } from "@/components/ui/empty"
import {
  InputGroup,
  InputGroupAddon,
  InputGroupButton,
  InputGroupTextarea,
} from "@/components/ui/input-group"
import {
  Message,
  MessageAvatar,
  MessageContent,
  MessageFooter,
  MessageGroup,
  MessageHeader,
} from "@/components/ui/message"
import {
  MessageScroller,
  MessageScrollerButton,
  MessageScrollerContent,
  MessageScrollerProvider,
  MessageScrollerViewport,
} from "@/components/ui/message-scroller"
import { Separator } from "@/components/ui/separator"
import { Tooltip, TooltipContent, TooltipTrigger } from "@/components/ui/tooltip"
import { cn } from "cn"
import { ShellHeader } from "@/components/admin/slots"

type Room = {
  roomId: string
  title: string
  avatarUrl: string | null
  topic: string | null
  encrypted: boolean
  direct: boolean
  membership: string
  memberCount: number
  invitedBy: string | null
}

type Reaction = { key: string; count: number; mine: boolean }

type Event = {
  eventId: string
  type: string
  sender: string
  senderName: string
  senderAvatar: string | null
  body: string | null
  formatted: string | null
  ts: number
  edited: boolean
  redacted: boolean
  decryptionError: string | null
  stateKey: string | null
  replyToId: string | null
  reactions: Reaction[]
}

const time = (ts: number) =>
  new Date(ts).toLocaleTimeString(undefined, { hour: "2-digit", minute: "2-digit" })

const day = (ts: number) =>
  new Date(ts).toLocaleDateString(undefined, { weekday: "long", day: "numeric", month: "long" })

const initial = (name: string) => name.replace(/^[#!@]/, "").charAt(0).toUpperCase()

// A state event renders as a muted one-liner, not a bubble -- Fractal's
// StateRow. Keeping them in the stream is what makes "Alice joined" sit in
// order with the messages around it.
const STATE_TYPES = new Set([
  "m.room.member",
  "m.room.name",
  "m.room.topic",
  "m.room.avatar",
  "m.room.canonical_alias",
  "m.room.join_rules",
  "m.room.history_visibility",
  "m.room.guest_access",
  "m.room.power_levels",
  "m.room.encryption",
  "m.room.create",
  "m.room.tombstone",
])

function StateRow({ event }: { event: Event }) {
  return (
    <div className="px-3 py-0.5 text-xs text-muted-foreground">
      <span className="font-medium">{event.senderName}</span> {event.body ?? event.type}
    </div>
  )
}

function DayDivider({ ts }: { ts: number }) {
  return (
    <div className="flex items-center gap-3 py-3">
      <Separator className="flex-1" />
      <span className="text-xs font-medium text-muted-foreground">{day(ts)}</span>
      <Separator className="flex-1" />
    </div>
  )
}

function Reactions({ reactions }: { reactions: Reaction[] }) {
  return (
    <div className="flex flex-wrap gap-1 pt-0.5">
      {reactions.map((reaction) => (
        <button
          key={reaction.key}
          type="button"
          className={cn(
            "rounded-full border px-1.5 py-0.5 text-xs transition-colors",
            reaction.mine
              ? "border-primary/40 bg-primary/10"
              : "border-transparent bg-muted hover:bg-muted/70"
          )}
        >
          <span className="mr-1">{reaction.key}</span>
          <span className="tabular-nums text-muted-foreground">{reaction.count}</span>
        </button>
      ))}
    </div>
  )
}

function MessageRow({
  event,
  own,
  showHeader,
}: {
  event: Event
  own: boolean
  showHeader: boolean
}) {
  return (
    <Message align={own ? "end" : "start"}>
      {/* The avatar slot is held even when the header is hidden, so a run of
          messages from one sender stays aligned with the first. */}
      <MessageAvatar className={cn(!showHeader && "invisible")}>
        <Avatar className="size-8">
          {event.senderAvatar && <AvatarImage src={event.senderAvatar} alt="" />}
          <AvatarFallback className="text-[11px]">{initial(event.senderName)}</AvatarFallback>
        </Avatar>
      </MessageAvatar>

      <MessageContent>
        {showHeader && (
          <MessageHeader>
            <span className="font-medium text-foreground">{event.senderName}</span>
          </MessageHeader>
        )}

        <div
          className={cn(
            "w-fit max-w-prose rounded-lg px-3 py-1.5",
            own ? "bg-primary text-primary-foreground" : "bg-muted",
            event.redacted && "italic opacity-60",
            event.decryptionError && "border border-dashed bg-transparent"
          )}
        >
          {event.decryptionError ? (
            <span className="flex items-center gap-1.5 text-sm text-muted-foreground">
              <ShieldAlert className="size-3.5" />
              Unable to decrypt
            </span>
          ) : event.redacted ? (
            <span className="text-sm">Message deleted</span>
          ) : event.formatted ? (
            <div
              className="text-sm [&_a]:underline [&_code]:rounded [&_code]:bg-black/10 [&_code]:px-1"
              dangerouslySetInnerHTML={{ __html: event.formatted }}
            />
          ) : (
            <span className="text-sm whitespace-pre-wrap">{event.body}</span>
          )}
        </div>

        {event.reactions.length > 0 && <Reactions reactions={event.reactions} />}

        <MessageFooter>
          <Tooltip>
            <TooltipTrigger render={<span className="tabular-nums">{time(event.ts)}</span>} />
            <TooltipContent>{new Date(event.ts).toLocaleString()}</TooltipContent>
          </Tooltip>
          {event.edited && <span className="ml-1">(edited)</span>}
        </MessageFooter>
      </MessageContent>
    </Message>
  )
}

function Timeline({ events, selfId }: { events: Event[]; selfId: string }) {
  if (events.length === 0) {
    return (
      <Empty className="flex-1">
        <EmptyHeader>
          <EmptyTitle>No messages yet</EmptyTitle>
          <EmptyDescription>Anything sent to this room will appear here.</EmptyDescription>
        </EmptyHeader>
      </Empty>
    )
  }

  // THE PROVIDER IS NOT OPTIONAL. MessageScrollerPrimitive.Root calls
  // useMessageScroller(), which throws "must be used within a MessageScroller"
  // when there is no provider above it -- so the whole timeline fails to
  // render rather than degrading. `autoScroll` is what keeps the view pinned
  // to the newest message, which is the behaviour the note at the top of this
  // file describes.
  return (
    <MessageScrollerProvider autoScroll>
      <MessageScroller className="min-h-0 flex-1">
        <MessageScrollerViewport>
          <MessageScrollerContent className="mx-auto flex w-full max-w-3xl flex-col gap-1 p-4">
            {events.map((event, index) => {
              const previous = events[index - 1]
              const newDay =
                !previous || new Date(previous.ts).toDateString() !== new Date(event.ts).toDateString()

              if (STATE_TYPES.has(event.type) && event.stateKey !== null) {
                return (
                  <div key={event.eventId}>
                    {newDay && <DayDivider ts={event.ts} />}
                    <StateRow event={event} />
                  </div>
                )
              }

              // EventHeaderState, decided here. Fractal has three values
              // (Full / TimestampOnly / Hidden); the header is dropped when the
              // previous event is the same sender, close in time, and not a
              // state row breaking the run.
              const sameSender =
                previous &&
                previous.sender === event.sender &&
                !STATE_TYPES.has(previous.type) &&
                event.ts - previous.ts < 5 * 60 * 1000

              return (
                <MessageGroup key={event.eventId}>
                  {newDay && <DayDivider ts={event.ts} />}
                  <MessageRow
                    event={event}
                    own={event.sender === selfId}
                    showHeader={!sameSender || newDay}
                  />
                </MessageGroup>
              )
            })}
          </MessageScrollerContent>
        </MessageScrollerViewport>

        {/* Pinned to the bottom until the reader scrolls up, then this appears. */}
        <MessageScrollerButton />
      </MessageScroller>
    </MessageScrollerProvider>
  )
}

function InvitePrompt({ room }: { room: Room }) {
  return (
    <Empty className="flex-1">
      <EmptyHeader>
        <EmptyMedia variant="icon">
          <Avatar className="size-12">
            {room.avatarUrl && <AvatarImage src={room.avatarUrl} alt="" />}
            <AvatarFallback>{initial(room.title)}</AvatarFallback>
          </Avatar>
        </EmptyMedia>
        <EmptyTitle>{room.title}</EmptyTitle>
        <EmptyDescription>
          {room.invitedBy ? `${room.invitedBy} invited you to this room.` : "You have been invited."}
          {room.topic && <span className="mt-2 block">{room.topic}</span>}
        </EmptyDescription>
      </EmptyHeader>
      <div className="flex gap-2">
        <Button>Accept</Button>
        <Button variant="outline">Decline</Button>
      </div>
    </Empty>
  )
}

function KnockPrompt({ room }: { room: Room }) {
  return (
    <Empty className="flex-1">
      <EmptyHeader>
        <EmptyTitle>Waiting to be let in</EmptyTitle>
        <EmptyDescription>
          You asked to join {room.title}. A moderator has to approve the request.
        </EmptyDescription>
      </EmptyHeader>
      <Button variant="outline">Cancel request</Button>
    </Empty>
  )
}

export default function MatrixRoom({
  room,
  events,
  selfId,
}: {
  room: Room
  events: Event[]
  selfId: string
}) {
  const encoded = encodeURIComponent(room.roomId)

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title={`${room.title} · matrix`} />

      <ShellHeader>
        <Link href="/matrix" className="text-muted-foreground hover:text-foreground md:hidden">
          <ArrowLeft className="size-4" />
        </Link>

        <Link href={`/matrix/rooms/${encoded}/about`} className="flex min-w-0 items-center gap-2">
          <Avatar className="size-7">
            {room.avatarUrl && <AvatarImage src={room.avatarUrl} alt="" />}
            <AvatarFallback className="text-[11px]">{initial(room.title)}</AvatarFallback>
          </Avatar>
          <div className="flex min-w-0 flex-col">
            <span className="truncate text-sm font-medium">{room.title}</span>
            {room.topic && (
              <span className="truncate text-xs text-muted-foreground">{room.topic}</span>
            )}
          </div>
        </Link>

        {room.encrypted && (
          <Tooltip>
            <TooltipTrigger render={<Lock className="size-3.5 shrink-0 text-muted-foreground" />} />
            <TooltipContent>End-to-end encrypted</TooltipContent>
          </Tooltip>
        )}

        <div className="ms-auto flex items-center gap-1">
          <Button variant="ghost" size="sm" nativeButton={false} render={<Link href={`/matrix/rooms/${encoded}/members`} />}>
              <Users className="size-4" />
              {room.memberCount > 0 && (
                <span className="ml-1 tabular-nums">{room.memberCount}</span>
              )}
            </Button>
          <Button variant="ghost" size="sm" nativeButton={false} render={<Link href={`/matrix/rooms/${encoded}/about`} />}>
              <Settings2 className="size-4" />
            </Button>
        </div>
      </ShellHeader>

      {room.membership === "invite" ? (
        <InvitePrompt room={room} />
      ) : room.membership === "knock" ? (
        <KnockPrompt room={room} />
      ) : (
        <>
          <Timeline events={events} selfId={selfId} />

          {/* MessageToolbar. The send path is not wired yet, so the controls
              are present and inert rather than absent -- the composer is the
              part of a chat UI that has to be laid out against real content. */}
          <div className="shrink-0 border-t p-3">
            <InputGroup className="mx-auto max-w-3xl">
              <InputGroupTextarea
                placeholder={`Message ${room.title}`}
                rows={1}
                className="max-h-40"
              />
              <InputGroupAddon align="block-end">
                <InputGroupButton variant="ghost" size="icon-xs" aria-label="Attach">
                  <Paperclip className="size-4" />
                </InputGroupButton>
                {room.encrypted && (
                  <Badge variant="secondary" size="sm" className="ml-1">
                    <Lock className="size-2.5" />
                    Encrypted
                  </Badge>
                )}
                <InputGroupButton size="icon-xs" className="ms-auto" aria-label="Send">
                  <Send className="size-4" />
                </InputGroupButton>
              </InputGroupAddon>
            </InputGroup>
          </div>
        </>
      )}
    </div>
  )
}
