# frozen_string_literal: true

# /matrix/rooms/:roomId/edit — Edit details
#
# Fractal: room_details/edit_details_subpage.{blp,rs}
#
# The room's name, topic and avatar, which are m.room.name, m.room.topic and m.room.avatar state events.
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
# session_view/room_details/edit_details_subpage.blp
#
#   <Adw.NavigationPage id="RoomDetailsEditDetailsSubpage">
#     <Adw.ToolbarView slot="child">
#       <Adw.HeaderBar>
#         <Gtk.Button id="back_button" />
#       </Adw.HeaderBar>
#       <Adw.PreferencesPage slot="content">
#         <Adw.PreferencesGroup>
#           <EditableAvatar id="avatar" />
#         </Adw.PreferencesGroup>
#         <Adw.PreferencesGroup>
#           <Adw.EntryRow id="name_entry_row">
#             <ActionButton id="name_button" />
#           </Adw.EntryRow>
#         </Adw.PreferencesGroup>
#         <Adw.PreferencesGroup id="topic_group">
#           <Gtk.Box>
#             <Gtk.ScrolledWindow>
#               <Gtk.TextView id="topic_text_view">
#                 <Gtk.TextBuffer id="topic_buffer" slot="buffer" />
#               </Gtk.TextView>
#             </Gtk.ScrolledWindow>
#             <LoadingButton id="save_topic_button" />
#           </Gtk.Box>
#         </Adw.PreferencesGroup>
#       </Adw.PreferencesPage>
#     </Adw.ToolbarView>
#   </Adw.NavigationPage>
#

get "/" do
  room = Models::Matrix::Room.first(room_id: params["roomId"]) || halt(404, "matrix: no such room\n")
  render(
    "matrix/rooms/[roomId]/edit",
    roomId:    room.room_id,
    roomTitle: room.title,
  )
end

post "/" do
  room_id = room_id!

  act! do
    unless params["name"].nil?
      Matrix::RoomActions.set_name(room_id, params["name"].to_s)
    end

    unless params["topic"].nil?
      Matrix::RoomActions.set_topic(room_id, params["topic"].to_s)
    end

    unless params["avatar_url"].nil?
      Matrix::RoomActions.set_avatar(room_id, params["avatar_url"].to_s)
    end
  end
end

__END__

import { Head, Link } from "@inertiajs/react"
import { ArrowLeft } from "lucide-react"

import { Alert, AlertDescription, AlertTitle } from "@/components/reui/alert"
import { ShellHeader } from "@/components/admin/slots"

export default function MatrixRoomsRoomidEdit({roomId, roomTitle}: {
  roomId: string
  roomTitle: string
}) {
  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title={`Edit details · ${roomTitle}`} />

      <ShellHeader>
        <Link href={`/matrix/rooms/${encodeURIComponent(roomId)}/about`} className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">Edit Room Details</h1>
      </ShellHeader>

      <div className="mx-auto flex w-full max-w-xl flex-col gap-4 p-6">
        <Alert>
          <AlertTitle>Not implemented</AlertTitle>
          <AlertDescription>
            Scaffolded from Fractal's <code>session_view/room_details/edit_details_subpage.blp</code>. The widget tree to rebuild is in the
            route file.
          </AlertDescription>
        </Alert>
      </div>
    </div>
  )
}
