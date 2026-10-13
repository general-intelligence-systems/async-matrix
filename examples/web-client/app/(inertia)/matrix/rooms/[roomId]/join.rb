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
  render(
    "matrix/rooms/[roomId]/join",
    roomId:    room.room_id,
    roomTitle: room.title,
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

import { Head, Link } from "@inertiajs/react"
import { ArrowLeft } from "lucide-react"

import { Alert, AlertDescription, AlertTitle } from "@/components/reui/alert"
import { ShellHeader } from "@/components/admin/slots"

export default function MatrixRoomsRoomidJoin({roomId, roomTitle}: {
  roomId: string
  roomTitle: string
}) {
  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title={`Invitation · ${roomTitle}`} />

      <ShellHeader>
        <Link href={`/matrix/rooms/${encodeURIComponent(roomId)}`} className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">Invitation</h1>
      </ShellHeader>

      <div className="mx-auto flex w-full max-w-xl flex-col gap-4 p-6">
        <Alert>
          <AlertTitle>Not implemented</AlertTitle>
          <AlertDescription>
            Scaffolded from Fractal's <code>session_view/invite.blp</code>. The widget tree to rebuild is in the
            route file.
          </AlertDescription>
        </Alert>
      </div>
    </div>
  )
}
