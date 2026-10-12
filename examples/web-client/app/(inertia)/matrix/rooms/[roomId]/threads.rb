# frozen_string_literal: true

# /matrix/rooms/:roomId/threads — Threads
#
# Fractal: nothing -- Fractal has no thread UI
#
# NOT IMPLEMENTED.
#
# The room's threads. NO FRACTAL EQUIVALENT: it has no thread support at all,
# so this is ours. Reads matrix_events.rel_type and
# matrix_thread_subscriptions.
# ── No Fractal widget tree ─────────────────────────────────────────────────
#
# Fractal has no thread UI at all, so there is nothing to catalog here. The
# nearest structure to borrow is the room timeline's -- see
# rooms/[roomId].rb, whose tree is the one this should echo.
#
# ── Build with ─────────────────────────────────────────────────────────────
#
# @reui/ai-chat-1 — its "tabbed switcher over pinned and recent chats" is a thread list:
#   root message, reply count, last activity, participation.
#
#   (no Fractal equivalent)  ->  ui/item rows + ui/tabs for subscribed / all
#   reply count              ->  ui/badge
#   participants             ->  stacked ui/avatar
#
# Threads. No Fractal equivalent -- it has no thread UI -- so this is ours,
# built on matrix_events.rel_type and matrix_thread_subscriptions.

get "/" do
  room = Models::Matrix::Room.first(room_id: params["roomId"]) || halt(404, "matrix: no such room\n")

  subscribed = Models::Matrix::ThreadSubscription
    .in_room(room.room_id).subscribed.select_map(:event_id)

  render(
    "matrix/rooms/[roomId]/threads",
    roomId:    room.room_id,
    roomTitle: room.title,
    # filter_map rather than map: a summary whose root event has not arrived
    # yet has nothing to draw, and the thread list is not the place to find out.
    threads:   Models::Matrix::ThreadSummary
      .in_room(room.room_id)
      .by_latest_reply
      .all
      .filter_map do |summary|
        root = summary.root

        if root
          {
            eventId:      summary.event_id,
            senderName:   root.sender_name,
            senderAvatar: root.sender_avatar_url,
            body:         root.content["body"],
            ts:           root.origin_server_ts.to_i,
            replyCount:   summary.reply_count.to_i,
            subscribed:   subscribed.include?(summary.event_id),
          }
        end
      end,
  )
end

__END__

import { Head, Link } from "@inertiajs/react"
import { ArrowLeft, MessagesSquare } from "lucide-react"

import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Badge } from "@/components/reui/badge"
import { Empty, EmptyDescription, EmptyHeader, EmptyMedia, EmptyTitle } from "@/components/ui/empty"
import { Item, ItemContent, ItemDescription, ItemMedia, ItemTitle } from "@/components/ui/item"
import { ScrollArea } from "@/components/ui/scroll-area"
import { ShellHeader } from "@/components/admin/slots"

type Thread = {
  eventId: string
  senderName: string
  senderAvatar: string | null
  body: string | null
  ts: number
  replyCount: number
  subscribed: boolean
}

const initial = (name: string) => name.replace(/^[#!@]/, "").charAt(0).toUpperCase()

export default function MatrixRoomThreads({
  roomId,
  roomTitle,
  threads,
}: {
  roomId: string
  roomTitle: string
  threads: Thread[]
}) {
  const encoded = encodeURIComponent(roomId)

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title={`Threads · ${roomTitle}`} />

      <ShellHeader>
        <Link href={`/matrix/rooms/${encoded}`} className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">Threads</h1>
      </ShellHeader>

      <ScrollArea className="min-h-0 flex-1">
        <div className="mx-auto w-full max-w-3xl p-4">
          {threads.length === 0 ? (
            <Empty className="py-12">
              <EmptyHeader>
                <EmptyMedia variant="icon">
                  <MessagesSquare />
                </EmptyMedia>
                <EmptyTitle>No threads</EmptyTitle>
                <EmptyDescription>
                  Replying in a thread to any message starts one.
                </EmptyDescription>
              </EmptyHeader>
            </Empty>
          ) : (
            <div className="flex flex-col gap-1">
              {threads.map((thread) => (
                <Item key={thread.eventId} render={<Link href={`/matrix/rooms/${encoded}/threads/${encodeURIComponent(thread.eventId)}`} />}>
                    <ItemMedia>
                      <Avatar className="size-8">
                        {thread.senderAvatar && <AvatarImage src={thread.senderAvatar} alt="" />}
                        <AvatarFallback className="text-[11px]">
                          {initial(thread.senderName)}
                        </AvatarFallback>
                      </Avatar>
                    </ItemMedia>
                    <ItemContent>
                      <ItemTitle className="line-clamp-1">{thread.body ?? "(no text)"}</ItemTitle>
                      <ItemDescription>
                        {thread.senderName} · {new Date(thread.ts).toLocaleDateString()}
                      </ItemDescription>
                    </ItemContent>
                    <div className="flex shrink-0 items-center gap-2">
                      {thread.subscribed && (
                        <Badge variant="secondary" size="sm">
                          Following
                        </Badge>
                      )}
                      <Badge variant="outline" size="sm" radius="full">
                        {thread.replyCount}
                      </Badge>
                    </div>
                  </Item>
              ))}
            </div>
          )}
        </div>
      </ScrollArea>
    </div>
  )
}
