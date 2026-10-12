# frozen_string_literal: true

# /matrix/rooms/:roomId/threads — Threads
#
# Fractal: nothing -- Fractal has no thread UI
#
# NOT IMPLEMENTED.
#
# The room's threads. NO FRACTAL EQUIVALENT: it has no thread support at all,
# so this is ours. Reads matrix_events.thread_root_id and
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
# built on matrix_events.thread_root_id and matrix_thread_subscriptions.
get "/" do
  room = matrix_room!

  roots = Models::Matrix::Event
    .where(user_id: matrix_user_id, room_id: room[:room_id])
    .exclude(thread_root_id: nil)
    .group_and_count(:thread_root_id)
    .to_h { |row| [row[:thread_root_id], row[:count]] }

  subscribed = DB[:matrix_thread_subscriptions]
    .where(user_id: matrix_user_id, room_id: room[:room_id], status: "subscribed")
    .select_map(:event_id)

  threads = Models::Matrix::Event
    .where(user_id: matrix_user_id, room_id: room[:room_id], event_id: roots.keys)
    .all
    .map do |event|
      matrix_event_json(event, []).merge(
        replyCount: roots[event[:event_id]].to_i,
        subscribed: subscribed.include?(event[:event_id]),
      )
    end
    .sort_by { |thread| -thread[:ts] }

  render(
    "matrix/rooms/[roomId]/threads",
    roomId: room[:room_id], roomTitle: matrix_room_title(room), threads: threads,
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
