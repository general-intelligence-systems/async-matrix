# frozen_string_literal: true

# /matrix/rooms/:roomId/permissions/members — Privileged members
#
# Fractal: room_details/permissions/members_subpage.{blp,rs}
#
# The members m.room.power_levels names, by level, which is who can act above the default.
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
# session_view/room_details/permissions/members_subpage.blp
#
#   <Adw.NavigationPage id="RoomDetailsPermissionsMembersSubpage">
#     <Adw.ToolbarView>
#       <Adw.HeaderBar>
#         <Gtk.ToggleButton id="search_button" />
#       </Adw.HeaderBar>
#       <Gtk.SearchBar id="search_bar">
#         <Adw.Clamp slot="child">
#           <Gtk.SearchEntry id="search_entry" />
#         </Adw.Clamp>
#       </Gtk.SearchBar>
#       <Gtk.Overlay slot="content">
#         <Gtk.Stack id="stack">
#           <Gtk.StackPage>
#             <Adw.StatusPage id="empty_page" slot="child" />
#           </Gtk.StackPage>
#           <Gtk.StackPage>
#             <ScrolledWindow slot="child">
#               <Adw.ClampScrollable slot="child">
#                 <Gtk.ListView id="list_view" slot="child" />
#               </Adw.ClampScrollable>
#             </ScrolledWindow>
#           </Gtk.StackPage>
#         </Gtk.Stack>
#         <Gtk.Button id="add_button">
#           <Gtk.Box slot="child">
#             <Gtk.Image />
#             <Gtk.Label />
#           </Gtk.Box>
#         </Gtk.Button>
#       </Gtk.Overlay>
#     </Adw.ToolbarView>
#   </Adw.NavigationPage>
#

get "/" do
  room = Models::Matrix::Room.first(room_id: params["roomId"]) || halt(404, "matrix: no such room\n")
  render(
    "matrix/rooms/[roomId]/permissions/members",
    roomId:    room.room_id,
    roomTitle: room.title,
  )
end

post "/" do
  act! do
    Matrix::RoomActions.set_power_level(
      room_id!,
      params["user_id"].to_s,
      params["level"].to_s.empty? ? nil : params["level"],
    )
  end
end

__END__

import { Head, Link } from "@inertiajs/react"
import { ArrowLeft } from "lucide-react"

import { Alert, AlertDescription, AlertTitle } from "@/components/reui/alert"
import { ShellHeader } from "@/components/admin/slots"

export default function MatrixRoomsRoomidPermissionsMembers({roomId, roomTitle}: {
  roomId: string
  roomTitle: string
}) {
  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title={`Privileged members · ${roomTitle}`} />

      <ShellHeader>
        <Link href={`/matrix/rooms/${encodeURIComponent(roomId)}/about`} className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">Privileged members</h1>
      </ShellHeader>

      <div className="mx-auto flex w-full max-w-xl flex-col gap-4 p-6">
        <Alert>
          <AlertTitle>Not implemented</AlertTitle>
          <AlertDescription>
            Scaffolded from Fractal's <code>session_view/room_details/permissions/members_subpage.blp</code>. The widget tree to rebuild is in the
            route file.
          </AlertDescription>
        </Alert>
      </div>
    </div>
  )
}
