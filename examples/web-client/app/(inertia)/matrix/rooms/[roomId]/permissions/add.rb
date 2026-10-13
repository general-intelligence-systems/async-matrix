# frozen_string_literal: true

# /matrix/rooms/:roomId/permissions/add — Add privileged members
#
# Fractal: room_details/permissions/add_members_subpage.{blp,rs}
#
# Picking members to raise above the default power level.
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
# session_view/room_details/permissions/add_members_subpage.blp
#
#   <Adw.NavigationPage id="RoomDetailsPermissionsAddMembersSubpage">
#     <Adw.ToolbarView slot="child">
#       <Adw.HeaderBar>
#         <Gtk.Button id="add_button" />
#       </Adw.HeaderBar>
#       <Adw.Clamp>
#         <PillSearchEntry id="search_entry" />
#       </Adw.Clamp>
#       <Adw.Clamp>
#         <Gtk.Box>
#           <Gtk.Label id="power_level_combo_label" />
#           <PowerLevelSelectionComboBox id="power_level_combo" />
#         </Gtk.Box>
#       </Adw.Clamp>
#       <Gtk.Stack id="stack" slot="content">
#         <Gtk.StackPage>
#           <Gtk.ScrolledWindow slot="child">
#             <Adw.ClampScrollable slot="child">
#               <Gtk.ListView id="list_view" slot="child" />
#             </Adw.ClampScrollable>
#           </Gtk.ScrolledWindow>
#         </Gtk.StackPage>
#         <Gtk.StackPage>
#           <Adw.StatusPage id="no_matching_page" slot="child" />
#         </Gtk.StackPage>
#       </Gtk.Stack>
#     </Adw.ToolbarView>
#   </Adw.NavigationPage>
#

get "/" do
  room = Models::Matrix::Room.first(room_id: params["roomId"]) || halt(404, "matrix: no such room\n")
  levels = room.power_levels
  assigned = (levels["users"] || {}).keys
  query = params["q"].to_s.downcase

  members = Models::Matrix::RoomMember
    .where(room_id: room.room_id, membership: "join")
    .exclude(member_id: assigned)
    .all
    .select{|member| query.empty? || member.name.to_s.downcase.include?(query) || member.member_id.downcase.include?(query)}

  render(
    "matrix/rooms/[roomId]/permissions/add",
    roomId:    room.room_id,
    roomTitle: room.title,
    query:     params["q"].to_s,
    members:   members.map{|member|
      { memberId: member.member_id, name: member.name, avatarUrl: member.avatar_url }
    },
  )
end

post "/" do
  act! do
    Matrix::RoomActions.set_power_level(room_id!, params["user_id"].to_s, params.fetch("level", 50))
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
import { Input } from "@/components/ui/input"

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

export default function MatrixRoomPermissionsAdd({
  roomId,
  roomTitle,
  query,
  members,
}: {
  roomId: string
  roomTitle: string
  query: string
  members: { memberId: string; name: string; avatarUrl: string | null }[]
}) {
  const encoded = encodeURIComponent(roomId)

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title={`Add Custom Permissions · ${roomTitle}`} />

      <ShellHeader>
        <Link
          href={`/matrix/rooms/${encoded}/permissions`}
          className="text-muted-foreground hover:text-foreground"
        >
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">Add Custom Permissions</h1>
      </ShellHeader>

      <div className="mx-auto flex w-full max-w-xl flex-col gap-4 p-6">
        <Input
          placeholder="Search for room members"
          defaultValue={query}
          onChange={(event) =>
            router.get(
              `/matrix/rooms/${encoded}/permissions/add`,
              { q: event.target.value },
              { preserveState: true, replace: true, preserveScroll: true },
            )
          }
        />

        <Card>
          <CardContent className="pt-6">
            <MemberList
              members={members}
              empty="No Matching Members Found"
              action="add"
              label="Add"
              roomId={roomId}
            />
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
