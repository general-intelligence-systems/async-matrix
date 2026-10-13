# frozen_string_literal: true

# /matrix/rooms/:roomId/permissions — Permissions
#
# Fractal: room_details/permissions/ (session/room/permissions.rs)
#
# m.room.power_levels, as the roles Fractal derives from it (Default, Custom,
# Moderator, Administrator, Creator, Muted) plus the per-action thresholds.
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
# session_view/room_details/permissions/permissions_subpage.blp
#
#   <Adw.NavigationPage id="RoomDetailsPermissionsSubpage">
#     <Adw.NavigationView slot="child" id="navigation">
#       <Adw.NavigationPage>
#         <Adw.ToolbarView slot="child">
#           <Adw.HeaderBar>
#             <Gtk.Button id="back_button" />
#             <LoadingButton id="save_button" />
#           </Adw.HeaderBar>
#           <Adw.PreferencesPage slot="content">
#             <Adw.PreferencesGroup id="room_actions_group">
#               <PowerLevelSelectionRow id="messages_row" />
#               <PowerLevelSelectionRow id="redact_own_row" />
#               <PowerLevelSelectionRow id="redact_others_row" />
#               <PowerLevelSelectionRow id="notify_room_row" />
#               <PowerLevelSelectionRow id="state_row" />
#               <PowerLevelSelectionRow id="name_row" />
#               <PowerLevelSelectionRow id="topic_row" />
#               <PowerLevelSelectionRow id="avatar_row" />
#               <PowerLevelSelectionRow id="aliases_row" />
#               <PowerLevelSelectionRow id="history_visibility_row" />
#               <PowerLevelSelectionRow id="encryption_row" />
#               <PowerLevelSelectionRow id="power_levels_row" />
#               <PowerLevelSelectionRow id="server_acl_row" />
#               <PowerLevelSelectionRow id="upgrade_row" />
#             </Adw.PreferencesGroup>
#             <Adw.PreferencesGroup id="member_actions_group">
#               <PowerLevelSelectionRow id="invite_row" />
#               <PowerLevelSelectionRow id="kick_row" />
#               <PowerLevelSelectionRow id="ban_row" />
#             </Adw.PreferencesGroup>
#             <Adw.PreferencesGroup id="members_group">
#               <Adw.SpinRow id="members_default_spin_row">
#                 <Gtk.Adjustment slot="adjustment" id="members_default_adjustment" />
#               </Adw.SpinRow>
#               <Adw.ActionRow id="members_default_text_row">
#                 <Gtk.Label id="members_default_label" />
#               </Adw.ActionRow>
#               <ButtonCountRow id="members_privileged_button" />
#             </Adw.PreferencesGroup>
#           </Adw.PreferencesPage>
#         </Adw.ToolbarView>
#       </Adw.NavigationPage>
#       <RoomDetailsPermissionsMembersSubpage id="members_subpage" />
#       <RoomDetailsPermissionsAddMembersSubpage id="add_members_subpage" />
#     </Adw.NavigationView>
#   </Adw.NavigationPage>
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
#             <Adw.StatusPage slot="child" id="empty_page" />
#           </Gtk.StackPage>
#           <Gtk.StackPage>
#             <ScrolledWindow slot="child">
#               <Adw.ClampScrollable slot="child">
#                 <Gtk.ListView slot="child" id="list_view" />
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
#       <Gtk.Stack slot="content" id="stack">
#         <Gtk.StackPage>
#           <Gtk.ScrolledWindow slot="child">
#             <Adw.ClampScrollable slot="child">
#               <Gtk.ListView slot="child" id="list_view" />
#             </Adw.ClampScrollable>
#           </Gtk.ScrolledWindow>
#         </Gtk.StackPage>
#         <Gtk.StackPage>
#           <Adw.StatusPage slot="child" id="no_matching_page" />
#         </Gtk.StackPage>
#       </Gtk.Stack>
#     </Adw.ToolbarView>
#   </Adw.NavigationPage>
#
# session_view/room_details/permissions/member_row.blp
#
#   <Box id="RoomDetailsPermissionsMemberRow">
#     <Avatar />
#     <Gtk.Box>
#       <Gtk.Label id="title" />
#       <Gtk.Label id="subtitle" />
#     </Gtk.Box>
#     <Gtk.Box id="suffixes">
#       <Gtk.Box id="selected_box">
#         <Gtk.Label id="selected_level_label" />
#         <RoleBadge id="selected_role_badge" />
#       </Gtk.Box>
#       <Gtk.Box id="arrow_box">
#         <Gtk.Image />
#         <PowerLevelSelectionPopover id="popover" />
#       </Gtk.Box>
#     </Gtk.Box>
#     <Gtk.GestureClick />
#   </Box>
#
# session_view/room_details/permissions/select_member_row.blp
#
#   <Adw.Bin id="RoomDetailsPermissionsSelectMemberRow">
#     <Gtk.Box slot="child" id="header">
#       <Avatar />
#       <Gtk.Box>
#         <Gtk.Label />
#         <Gtk.Label />
#       </Gtk.Box>
#       <Gtk.CheckButton />
#     </Gtk.Box>
#   </Adw.Bin>
#
# components/power_level_selection/combo_box.blp
#
#   <Gtk.ToggleButton id="PowerLevelSelectionComboBox">
#     <Gtk.Box slot="child">
#       <Gtk.Box id="selected_box">
#         <Gtk.Label id="selected_level_label" />
#         <RoleBadge id="selected_role_badge" />
#       </Gtk.Box>
#       <Gtk.Image />
#       <PowerLevelSelectionPopover id="popover" />
#     </Gtk.Box>
#   </Gtk.ToggleButton>
#
# components/power_level_selection/popover.blp
#
#   <Gtk.Popover id="PowerLevelSelectionPopover">
#     <Gtk.ScrolledWindow slot="child">
#       <Gtk.Box slot="child">
#         <Gtk.ListBox>
#           <Gtk.ListBoxRow id="admin_row">
#             <Gtk.Box slot="child">
#               <Gtk.Label />
#               <RoleBadge />
#               <Image id="admin_selected" />
#             </Gtk.Box>
#           </Gtk.ListBoxRow>
#           <Gtk.ListBoxRow id="mod_row">
#             <Gtk.Box slot="child">
#               <Gtk.Label />
#               <RoleBadge />
#               <Gtk.Image id="mod_selected" />
#             </Gtk.Box>
#           </Gtk.ListBoxRow>
#           <Gtk.ListBoxRow id="default_row">
#             <Gtk.Box slot="child">
#               <Gtk.Label id="default_pl_label" />
#               <RoleBadge />
#               <Gtk.Image id="default_selected" />
#             </Gtk.Box>
#           </Gtk.ListBoxRow>
#           <Gtk.ListBoxRow id="muted_row">
#             <Gtk.Box slot="child">
#               <Gtk.Label id="muted_pl_label" />
#               <RoleBadge />
#               <Gtk.Image id="muted_selected" />
#             </Gtk.Box>
#           </Gtk.ListBoxRow>
#         </Gtk.ListBox>
#         <Gtk.Separator />
#         <Gtk.ListBox>
#           <Adw.SpinRow id="custom_row">
#             <Gtk.Adjustment slot="adjustment" id="custom_adjustment" />
#             <Gtk.Button id="custom_confirm" />
#           </Adw.SpinRow>
#         </Gtk.ListBox>
#       </Gtk.Box>
#     </Gtk.ScrolledWindow>
#   </Gtk.Popover>
#
# components/power_level_selection/row.blp
#
#   <Adw.PreferencesRow id="PowerLevelSelectionRow">
#     <Gtk.Box slot="child" id="header">
#       <Gtk.Box id="title_box">
#         <Gtk.Label id="title" />
#         <Adw.Bin id="subtitle_bin" />
#       </Gtk.Box>
#       <Gtk.Box id="suffixes">
#         <Adw.Bin id="combo_selection_bin" />
#         <Gtk.Box id="arrow_box">
#           <LoadingBin id="loading_bin">
#             <Image slot="child" />
#           </LoadingBin>
#           <PowerLevelSelectionPopover id="popover" />
#         </Gtk.Box>
#       </Gtk.Box>
#     </Gtk.Box>
#   </Adw.PreferencesRow>
#   <Gtk.Box id="selected_box">
#     <Gtk.Label id="selected_level_label" />
#     <Gtk.MenuButton id="creator_info_button">
#       <Gtk.Popover slot="popover">
#         <Gtk.Label slot="child" />
#       </Gtk.Popover>
#     </Gtk.MenuButton>
#     <RoleBadge id="selected_role_badge" />
#   </Gtk.Box>
#
# ── Build with ─────────────────────────────────────────────────────────────
#
# @reui/solution-users-3 — "Workspace roles and permissions access matrix with locked
#   Owner column and grouped scope toggles". THE CLOSEST SINGLE MATCH IN THE CATALOG:
#   m.room.power_levels IS an access matrix, the locked Owner column is the room
#   creator you cannot demote, and grouped scopes are events_default / state_default /
#   redact / kick / ban / invite.
#   @reui/settings-5 — "Role Permissions Settings Panel with Two-Column Switch Toggle
#   Grid" is the smaller version if the matrix is too much.
#
#   PermissionsSubpage rows          ->  the matrix rows, one per action
#   PowerLevelSelection ComboBox     ->  ui/select — Default / Moderator / Admin / Custom
#   PowerLevelSelection Popover+Row  ->  ui/popover + ui/number-field for a custom level
#   MemberRow (privileged members)   ->  ui/item + ui/avatar
#   SelectMemberRow / AddMembers     ->  reui/autocomplete over the member list
#   MemberRole enum                  ->  ui/badge — Creator is the locked column
#
# INSTALL, reui registry: @reui/number-field
#
# m.room.power_levels as an access matrix. The actions are the spec's, plus
# whatever the room has put under `events`.

# The actions the view draws a row for, and the spec's default when
# m.room.power_levels names no level of its own. `nil` means it falls back to
# state_default, which is itself one of the rows.
ACTIONS = [
  ["invite",              "Invite people",           0],
  ["kick",                "Remove people",           50],
  ["ban",                 "Ban people",              50],
  ["redact",              "Delete others' messages", 50],
  ["events_default",      "Send messages",           0],
  ["state_default",       "Change settings",         50],
  ["m.room.name",         "Change the name",         nil],
  ["m.room.topic",        "Change the topic",        nil],
  ["m.room.avatar",       "Change the avatar",       nil],
  ["m.room.power_levels", "Change permissions",      nil],
  ["m.room.tombstone",    "Upgrade the room",        100],
].freeze

# The actions the view draws a row for, and the spec's default when
# m.room.power_levels names no level of its own. `nil` means it falls back to
# state_default, which is itself one of the rows.
ACTIONS = [
  ["invite",              "Invite people",           0],
  ["kick",                "Remove people",           50],
  ["ban",                 "Ban people",              50],
  ["redact",              "Delete others' messages", 50],
  ["events_default",      "Send messages",           0],
  ["state_default",       "Change settings",         50],
  ["m.room.name",         "Change the name",         nil],
  ["m.room.topic",        "Change the topic",        nil],
  ["m.room.avatar",       "Change the avatar",       nil],
  ["m.room.power_levels", "Change permissions",      nil],
  ["m.room.tombstone",    "Upgrade the room",        100],
].freeze

get "/" do
  room = Models::Matrix::Room.first(room_id: params["roomId"]) || halt(404, "matrix: no such room\n")
  levels = room.power_levels
  state_default = (levels["state_default"] || 50).to_i

  render(
    "matrix/rooms/[roomId]/permissions",
    roomId:     room.room_id,
    roomTitle:  room.title,
    actions:    ACTIONS.map do |key, label, default|
      if default.nil?
        level = levels.dig("events", key) || state_default
      else
        level = levels[key] || default
      end

      { key: key, label: label, level: level.to_i }
    end,
    default:    (levels["users_default"] || 0).to_i,
    # Anyone with an explicit entry, which is the list worth showing -- the
    # other members are all at users_default by definition.
    privileged: (levels["users"] || {}).sort_by{|_id, level| -level.to_i}.map do |member_id, level|
      {
        memberId: member_id,
        level:    level.to_i,
        role:     Models::Matrix::RoomMember::ROLES.fetch(level.to_i, "Custom"),
        creator:  member_id == room.creator,
      }
    end,
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
import { ArrowLeft, Lock } from "lucide-react"

import { Badge } from "@/components/reui/badge"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { ScrollArea } from "@/components/ui/scroll-area"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { ShellHeader } from "@/components/admin/slots"

type Action = { key: string; label: string; level: number }
type Privileged = { memberId: string; level: number; role: string; creator: boolean }

// The three named rungs. Anything else is Custom and shows its number.
const RUNGS = [
  { value: "0", label: "Default" },
  { value: "50", label: "Moderator" },
  { value: "100", label: "Admin" },
]

const rungFor = (level: number) =>
  RUNGS.find((rung) => Number(rung.value) === level)?.value ?? "custom"

export default function MatrixRoomPermissions({
  roomId,
  roomTitle,
  actions,
  default: usersDefault,
  privileged,
}: {
  roomId: string
  roomTitle: string
  actions: Action[]
  default: number
  privileged: Privileged[]
}) {
  const encoded = encodeURIComponent(roomId)

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title={`Permissions · ${roomTitle}`} />

      <ShellHeader>
        <Link href={`/matrix/rooms/${encoded}/about`} className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">Permissions</h1>
      </ShellHeader>

      <ScrollArea className="min-h-0 flex-1">
        <div className="mx-auto flex w-full max-w-3xl flex-col gap-4 p-6">
          <Card>
            <CardHeader>
              <CardTitle className="text-sm">What each level may do</CardTitle>
              <CardDescription>
                The level a member needs before the action is allowed. Everyone starts at{" "}
                {usersDefault}.
              </CardDescription>
            </CardHeader>
            <CardContent>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Action</TableHead>
                    <TableHead className="w-44">Required level</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {actions.map((action) => {
                    const rung = rungFor(action.level)
                    return (
                      <TableRow key={action.key}>
                        <TableCell>
                          <span>{action.label}</span>
                          <code className="ml-2 font-mono text-xs text-muted-foreground">
                            {action.key}
                          </code>
                        </TableCell>
                        <TableCell>
                          <Select defaultValue={rung}>
                            <SelectTrigger size="sm">
                              <SelectValue />
                            </SelectTrigger>
                            <SelectContent>
                              {RUNGS.map((option) => (
                                <SelectItem key={option.value} value={option.value}>
                                  {option.label}
                                </SelectItem>
                              ))}
                              {rung === "custom" && (
                                <SelectItem value="custom">Custom ({action.level})</SelectItem>
                              )}
                            </SelectContent>
                          </Select>
                        </TableCell>
                      </TableRow>
                    )
                  })}
                </TableBody>
              </Table>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Members with a level set</CardTitle>
              <CardDescription>
                Everyone else is at the default. The room creator cannot be demoted.
              </CardDescription>
            </CardHeader>
            <CardContent className="flex flex-col gap-1">
              {privileged.length === 0 ? (
                <p className="py-4 text-sm text-muted-foreground">
                  Nobody has been given a level above the default.
                </p>
              ) : (
                privileged.map((member) => (
                  <div
                    key={member.memberId}
                    className="flex items-center justify-between gap-3 rounded-md px-2 py-1.5 hover:bg-accent/50"
                  >
                    <Link
                      href={`/matrix/users/${encodeURIComponent(member.memberId)}`}
                      className="truncate font-mono text-sm hover:underline"
                    >
                      {member.memberId}
                    </Link>
                    <div className="flex shrink-0 items-center gap-2">
                      <Badge variant={member.level >= 100 ? "primary" : "secondary"} size="sm">
                        {member.role} · {member.level}
                      </Badge>
                      {member.creator && (
                        <Lock className="size-3 text-muted-foreground" aria-label="Room creator" />
                      )}
                    </div>
                  </div>
                ))
              )}
              <Button variant="outline" size="sm" className="mt-2 self-start">
                Add member
              </Button>
            </CardContent>
          </Card>
        </div>
      </ScrollArea>
    </div>
  )
}
