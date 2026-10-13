# frozen_string_literal: true

# /matrix/rooms/:roomId/requests — Join requests
#
# Fractal: session_view/invite_request.{blp,rs}
#
# NOT IMPLEMENTED.
#
# Knocks waiting on a decision, which is what m.room.member with membership knock produces.
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
# session_view/invite_request.blp
#
#   <Adw.Bin id="ContentInviteRequest">
#     <Adw.ToolbarView>
#       <Adw.HeaderBar id="header_bar">
#         <Adw.WindowTitle />
#       </Adw.HeaderBar>
#       <Gtk.ScrolledWindow slot="content">
#         <Adw.Clamp slot="child">
#           <Gtk.Box slot="child">
#             <Avatar id="avatar" />
#             <Gtk.Box>
#               <Gtk.Label id="display_name" />
#               <Gtk.Label id="room_alias" />
#             </Gtk.Box>
#             <Gtk.Label id="room_topic" />
#             <Gtk.Label />
#             <Gtk.Box>
#               <LoadingButton id="retract_button" />
#             </Gtk.Box>
#           </Gtk.Box>
#         </Adw.Clamp>
#       </Gtk.ScrolledWindow>
#     </Adw.ToolbarView>
#   </Adw.Bin>
#

get "/" do
  room = Models::Matrix::Room.first(room_id: params["roomId"]) || halt(404, "matrix: no such room\n")

  render(
    "matrix/rooms/[roomId]/requests",
    roomId:    room.room_id,
    roomTitle: room.title,
    requests:  Models::Matrix::RoomMember
      .where(room_id: room.room_id, membership: "knock")
      .all
      .map{|member|
        { memberId: member.member_id, name: member.name, avatarUrl: member.avatar_url }
      },
  )
end

post "/" do
  halt(501, "matrix: not implemented\n")
end

__END__

import { Head, Link, router } from "@inertiajs/react"
import { ArrowLeft } from "lucide-react"

import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { Empty, EmptyDescription, EmptyHeader, EmptyTitle } from "@/components/ui/empty"
import { Item, ItemContent, ItemDescription, ItemTitle } from "@/components/ui/item"
import { ShellHeader } from "@/components/admin/slots"

export default function MatrixRoomRequests({
  roomId,
  roomTitle,
  requests,
}: {
  roomId: string
  roomTitle: string
  requests: { memberId: string; name: string; avatarUrl: string | null }[]
}) {
  const encoded = encodeURIComponent(roomId)
  const act = (action: string, userId: string) =>
    router.post(`/matrix/rooms/${encoded}/members`, { action, user_id: userId }, { preserveScroll: true })

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title={`Join requests · ${roomTitle}`} />

      <ShellHeader>
        <Link href={`/matrix/rooms/${encoded}/about`} className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">Join requests</h1>
      </ShellHeader>

      <div className="mx-auto flex w-full max-w-xl flex-col gap-4 p-6">
        {requests.length === 0 ? (
          <Empty className="py-16">
            <EmptyHeader>
              <EmptyTitle>No join requests</EmptyTitle>
              <EmptyDescription>
                A knock appears here when someone asks to join this room.
              </EmptyDescription>
            </EmptyHeader>
          </Empty>
        ) : (
          <Card>
            <CardContent className="flex flex-col gap-2 pt-6">
              {requests.map((request) => (
                <Item key={request.memberId}>
                  <Avatar className="size-8">
                    {request.avatarUrl && <AvatarImage src={request.avatarUrl} alt="" />}
                    <AvatarFallback className="text-[11px]">
                      {request.name.replace(/^@/, "").charAt(0).toUpperCase()}
                    </AvatarFallback>
                  </Avatar>
                  <ItemContent>
                    <ItemTitle>{request.name}</ItemTitle>
                    <ItemDescription className="font-mono text-xs">{request.memberId}</ItemDescription>
                  </ItemContent>
                  <Button size="sm" onClick={() => act("invite", request.memberId)}>
                    Approve
                  </Button>
                  <Button size="sm" variant="outline" onClick={() => act("kick", request.memberId)}>
                    Deny
                  </Button>
                </Item>
              ))}
            </CardContent>
          </Card>
        )}
      </div>
    </div>
  )
}
