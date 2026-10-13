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
  levels = room.power_levels

  render(
    "matrix/rooms/[roomId]/permissions/members",
    roomId:    room.room_id,
    roomTitle: room.title,
    members:   (levels["users"] || {}).sort_by{|_id, level| -level.to_i}.map{|member_id, level|
      member = Models::Matrix::RoomMember.first(room_id: room.room_id, member_id: member_id)

      {
        memberId:  member_id,
        name:      member&.name || member_id,
        avatarUrl: member&.avatar_url,
        level:     level.to_i,
      }
    },
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

import { Head, Link, router } from "@inertiajs/react"
import { ArrowLeft } from "lucide-react"

import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Badge } from "@/components/reui/badge"
import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { Empty, EmptyHeader, EmptyTitle } from "@/components/ui/empty"
import { Item, ItemContent, ItemDescription, ItemTitle } from "@/components/ui/item"
import { ShellHeader } from "@/components/admin/slots"

function MemberList({
  members,
  empty,
  action,
  label,
  roomId,
}: {
  members: { memberId: string; name: string; avatarUrl: string | null; level?: number }[]
  empty: string
  action: string
  label: string
  roomId: string
}) {
  const encoded = encodeURIComponent(roomId)

  if (members.length === 0) {
    return (
      <Empty className="py-10">
        <EmptyHeader>
          <EmptyTitle>{empty}</EmptyTitle>
        </EmptyHeader>
      </Empty>
    )
  }

  return (
    <div className="flex flex-col gap-1">
      {members.map((member) => (
        <Item key={member.memberId}>
          <Avatar className="size-8">
            {member.avatarUrl && <AvatarImage src={member.avatarUrl} alt="" />}
            <AvatarFallback className="text-[11px]">
              {member.name.replace(/^@/, "").charAt(0).toUpperCase()}
            </AvatarFallback>
          </Avatar>
          <ItemContent>
            <ItemTitle>{member.name}</ItemTitle>
            <ItemDescription className="font-mono text-xs">{member.memberId}</ItemDescription>
          </ItemContent>
          {member.level !== undefined && (
            <Badge variant="secondary" size="sm">
              {member.level}
            </Badge>
          )}
          <Button
            size="sm"
            variant="outline"
            onClick={() =>
              router.post(
                `/matrix/rooms/${encoded}/permissions/${action}`,
                { user_id: member.memberId, level: action === "add" ? 50 : "" },
                { preserveScroll: true },
              )
            }
          >
            {label}
          </Button>
        </Item>
      ))}
    </div>
  )
}

export default function MatrixRoomPermissionsMembers({
  roomId,
  roomTitle,
  members,
}: {
  roomId: string
  roomTitle: string
  members: { memberId: string; name: string; avatarUrl: string | null; level: number }[]
}) {
  const encoded = encodeURIComponent(roomId)

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title={`Members With Assigned Power Levels · ${roomTitle}`} />

      <ShellHeader>
        <Link
          href={`/matrix/rooms/${encoded}/permissions`}
          className="text-muted-foreground hover:text-foreground"
        >
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">Members With Assigned Power Levels</h1>
      </ShellHeader>

      <div className="mx-auto flex w-full max-w-xl flex-col gap-4 p-6">
        <Card>
          <CardContent className="pt-6">
            <MemberList
              members={members}
              empty="No Room Members"
              action="members"
              label="Reset"
              roomId={roomId}
            />
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
