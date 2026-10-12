# frozen_string_literal: true

# /matrix/rooms/:roomId/members — Members
#
# Fractal: room_details/members_page/ (+ members_list_view/)
#
# NOT IMPLEMENTED.
#
# The member list, ?membership=join|invite|ban|knock for Fractal's four
# MembershipListKind tabs. Rows link to /matrix/users/:userId, which is NOT
# under this route -- see that file.
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
# session_view/room_details/members_page/mod.blp
#
#   <Adw.NavigationPage id="MembersPage">
#     <Adw.NavigationView id="navigation_view" />
#   </Adw.NavigationPage>
#
# session_view/room_details/members_page/members_list_view/mod.blp
#
#   <Adw.NavigationPage id="ContentMembersListView">
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
#             <Adw.Spinner slot="child" />
#           </Gtk.StackPage>
#           <Gtk.StackPage id="empty_stack_page">
#             <Adw.StatusPage slot="child" id="empty_page">
#               <Adw.Clamp slot="child">
#                 <Gtk.ListBox slot="child" id="empty_listbox" />
#               </Adw.Clamp>
#             </Adw.StatusPage>
#           </Gtk.StackPage>
#           <Gtk.StackPage>
#             <Adw.StatusPage slot="child" id="error_page">
#               <Gtk.Button slot="child" />
#             </Adw.StatusPage>
#           </Gtk.StackPage>
#           <Gtk.StackPage id="members_stack_page">
#             <Gtk.ScrolledWindow slot="child">
#               <Adw.ClampScrollable slot="child">
#                 <Gtk.ListView slot="child" id="list_view">
#                   <Gtk.BuilderListItemFactory slot="factory">
#                     <ContentMemberItemRow slot="child" id="row" />
#                   </Gtk.BuilderListItemFactory>
#                 </Gtk.ListView>
#               </Adw.ClampScrollable>
#             </Gtk.ScrolledWindow>
#           </Gtk.StackPage>
#         </Gtk.Stack>
#         <Gtk.Button id="invite_button">
#           <Gtk.Box slot="child">
#             <Gtk.Image />
#             <Gtk.Label />
#           </Gtk.Box>
#         </Gtk.Button>
#       </Gtk.Overlay>
#     </Adw.ToolbarView>
#   </Adw.NavigationPage>
#
# session_view/room_details/members_page/members_list_view/membership_subpage_row.blp
#
#   <Gtk.ListBoxRow id="MembersPageMembershipSubpageRow">
#     <Gtk.Box slot="child">
#       <Gtk.Image />
#       <Gtk.Label id="title" />
#       <Gtk.Label id="members_count" />
#       <Gtk.Image />
#     </Gtk.Box>
#   </Gtk.ListBoxRow>
#
# session_view/room_details/member_row.blp
#
#   <Box id="ContentMemberRow">
#     <Avatar />
#     <Gtk.Box>
#       <Gtk.Box>
#         <Gtk.Label />
#         <Gtk.Image />
#         <RoleBadge id="role_badge" />
#       </Gtk.Box>
#       <Gtk.Label />
#     </Gtk.Box>
#   </Box>
#
# ── Build with ─────────────────────────────────────────────────────────────
#
# @reui/solution-users-1 — "Workspace Members Directory Grid with Roles, SSO/2FA Status,
#   and Bulk Role Actions". Roles are power levels and the status column is verification
#   state. Bulk role actions map to bulk power-level changes.
#
#   MembershipListKind tabs (4)  ->  ui/tabs — Join / Invite / Ban / Knock
#   MembersListView              ->  reui/data-grid, or ui/item rows if a grid is heavy for a
#                                     5-person room
#   MemberRow                    ->  ui/avatar + name + ui/badge(role)
#   Gtk.SearchEntry              ->  the data grid's own filter
#   MembershipSubpageRow         ->  ui/item linking to the per-membership list
#   display name disambiguation  ->  matrix_member_display_names decides; render @id when shared
#
# INSTALL, reui registry: @reui/data-grid
#
# The member list, one tab per MembershipListKind.
get "/" do
  room = matrix_room!
  membership = %w[join invite ban knock].include?(params["membership"]) ? params["membership"] : "join"

  render(
    "matrix/rooms/[roomId]/members",
    roomId:     room[:room_id],
    roomTitle:  matrix_room_title(room),
    membership: membership,
    members:    matrix_members(room, membership: membership),
    counts:     %w[join invite ban knock].to_h do |kind|
      [kind, Models::Matrix::RoomMember.where(
        room_id: room[:room_id], membership: kind,
      ).count]
    end,
  )
end

__END__

import { Head, Link, router } from "@inertiajs/react"
import { ArrowLeft, UserPlus } from "lucide-react"

import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Badge } from "@/components/reui/badge"
import { Button } from "@/components/ui/button"
import { Empty, EmptyDescription, EmptyHeader, EmptyTitle } from "@/components/ui/empty"
import { Item, ItemContent, ItemDescription, ItemMedia, ItemTitle } from "@/components/ui/item"
import { ScrollArea } from "@/components/ui/scroll-area"
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { ShellHeader } from "@/components/admin/slots"

type Member = {
  memberId: string
  displayName: string
  avatarUrl: string | null
  membership: string
  powerLevel: number
  role: string
}

const TABS = [
  { value: "join", label: "Joined" },
  { value: "invite", label: "Invited" },
  { value: "knock", label: "Requested" },
  { value: "ban", label: "Banned" },
]

const initial = (name: string) => name.replace(/^[#!@]/, "").charAt(0).toUpperCase()

export default function MatrixRoomMembers({
  roomId,
  roomTitle,
  membership,
  members,
  counts,
}: {
  roomId: string
  roomTitle: string
  membership: string
  members: Member[]
  counts: Record<string, number>
}) {
  const encoded = encodeURIComponent(roomId)

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title={`Members · ${roomTitle}`} />

      <ShellHeader>
        <Link
          href={`/matrix/rooms/${encoded}`}
          className="text-muted-foreground hover:text-foreground"
        >
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">Members</h1>
        <Button size="sm" className="ms-auto" nativeButton={false} render={<Link href={`/matrix/rooms/${encoded}/invite`} />}>
            <UserPlus className="size-4" />
            Invite
          </Button>
      </ShellHeader>

      <div className="border-b px-4 py-2">
        {/* Membership is a query param, not client state: a filtered member
            list is a link somebody can send. */}
        <Tabs
          value={membership}
          onValueChange={(value) =>
            router.get(`/matrix/rooms/${encoded}/members`, { membership: value }, { preserveState: false })
          }
        >
          <TabsList>
            {TABS.map((tab) => (
              <TabsTrigger key={tab.value} value={tab.value}>
                {tab.label}
                {counts[tab.value] > 0 && (
                  <Badge variant="secondary" size="sm" className="ml-1.5">
                    {counts[tab.value]}
                  </Badge>
                )}
              </TabsTrigger>
            ))}
          </TabsList>
        </Tabs>
      </div>

      <ScrollArea className="min-h-0 flex-1">
        <div className="mx-auto w-full max-w-3xl p-4">
          {members.length === 0 ? (
            <Empty className="py-12">
              <EmptyHeader>
                <EmptyTitle>Nobody here</EmptyTitle>
                <EmptyDescription>No members with this membership.</EmptyDescription>
              </EmptyHeader>
            </Empty>
          ) : (
            <div className="flex flex-col gap-1">
              {members.map((member) => (
                <Item key={member.memberId} render={<Link href={`/matrix/users/${encodeURIComponent(member.memberId)}`} />}>
                    <ItemMedia>
                      <Avatar className="size-8">
                        {member.avatarUrl && <AvatarImage src={member.avatarUrl} alt="" />}
                        <AvatarFallback className="text-[11px]">
                          {initial(member.displayName)}
                        </AvatarFallback>
                      </Avatar>
                    </ItemMedia>
                    <ItemContent>
                      <ItemTitle>{member.displayName}</ItemTitle>
                      <ItemDescription>{member.memberId}</ItemDescription>
                    </ItemContent>
                    {member.role !== "Default" && (
                      <Badge variant={member.role === "Admin" ? "primary" : "secondary"} size="sm">
                        {member.role}
                      </Badge>
                    )}
                  </Item>
              ))}
            </div>
          )}
        </div>
      </ScrollArea>
    </div>
  )
}
