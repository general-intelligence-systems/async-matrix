# frozen_string_literal: true

# /matrix/rooms/:roomId/join — Invitation
#
# Fractal: session_view/invite.{blp,rs}
#
# An invitation you have received: who sent it, and accept or decline. Distinct from /invite, which is the subpage for inviting others.
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
# session_view/invite.blp
#
#   <Adw.Bin id="ContentInvite">
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
#             <LabelWithWidgets id="inviter" />
#             <Gtk.Box>
#               <LoadingButton id="decline_button" />
#               <LoadingButton id="accept_button" />
#             </Gtk.Box>
#           </Gtk.Box>
#         </Adw.Clamp>
#       </Gtk.ScrolledWindow>
#     </Adw.ToolbarView>
#   </Adw.Bin>
#

get "/" do
  room = Models::Matrix::Room.first(room_id: params["roomId"]) || halt(404, "matrix: no such room\n")
  me = Models::Matrix::Credential.first&.matrix_user_id.to_s

  render(
    "matrix/rooms/[roomId]/join",
    roomId:     room.room_id,
    roomTitle:  room.title,
    avatarUrl:  room.avatar_url,
    topic:      room.topic,
    membership: room.membership,
    inviter:    Models::Matrix::RoomState.first(
      room_id: room.room_id, event_type: "m.room.member", state_key: me,
    )&.sender,
  )
end

post "/" do
  room_id = room_id!

  act! do
    case params["action"].to_s
    when "decline"
      Matrix::RoomActions.leave(room_id)
    else
      Matrix::RoomActions.join(room_id)
    end
  end
end

__END__

import { Head, Link, router } from "@inertiajs/react"
import { ArrowLeft } from "lucide-react"

import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Button } from "@/components/ui/button"
import { Empty, EmptyDescription, EmptyHeader, EmptyMedia, EmptyTitle } from "@/components/ui/empty"
import { ShellHeader } from "@/components/admin/slots"

export default function MatrixRoomJoin({
  roomId,
  roomTitle,
  avatarUrl,
  topic,
  membership,
  inviter,
}: {
  roomId: string
  roomTitle: string
  avatarUrl: string | null
  topic: string | null
  membership: string
  inviter: string | null
}) {
  const encoded = encodeURIComponent(roomId)
  const act = (action: string) =>
    router.post(`/matrix/rooms/${encoded}/join`, { action }, { preserveScroll: true })

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title={`Invitation · ${roomTitle}`} />

      <ShellHeader>
        <Link href="/matrix" className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">Invitation</h1>
      </ShellHeader>

      <Empty className="flex-1">
        <EmptyHeader>
          <EmptyMedia variant="icon">
            <Avatar className="size-12">
              {avatarUrl && <AvatarImage src={avatarUrl} alt="" />}
              <AvatarFallback>{roomTitle.charAt(0).toUpperCase()}</AvatarFallback>
            </Avatar>
          </EmptyMedia>
          <EmptyTitle>{roomTitle}</EmptyTitle>
          <EmptyDescription>
            {inviter ? `${inviter} invited you.` : "You were invited to this room."}
            {topic ? ` ${topic}` : ""}
          </EmptyDescription>
        </EmptyHeader>

        <div className="flex gap-2">
          <Button onClick={() => act("join")}>Accept</Button>
          <Button variant="outline" onClick={() => act("decline")}>
            Decline
          </Button>
        </div>
        {membership === "knock" && (
          <p className="text-xs text-muted-foreground">You asked to join. A moderator decides.</p>
        )}
      </Empty>
    </div>
  )
}
