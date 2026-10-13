# frozen_string_literal: true

# /matrix/rooms/:roomId/about — About
#
# Fractal: room_details/general_page.blp + edit_details_subpage.blp
#
# Avatar, name, topic, member count -- editable in place when
# Permissions#can_change_* allows it. Fractal splits view from edit because
# its PreferencesWindow pushes a subpage; one page does both here, and the
# rows that only navigated elsewhere are the URL bar's job now.
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
# session_view/room_details/mod.blp
#
#   <Adw.PreferencesWindow id="RoomDetails" />
#
# session_view/room_details/general_page.blp
#
#   <Adw.PreferencesPage id="RoomDetailsGeneralPage">
#     <Adw.PreferencesGroup>
#       <Gtk.Box>
#         <Avatar id="avatar" />
#         <Gtk.Label />
#         <Gtk.Label id="room_topic" />
#         <Gtk.Button id="edit_details_btn" />
#       </Gtk.Box>
#     </Adw.PreferencesGroup>
#     <Adw.PreferencesGroup id="direct_members_group">
#       <Gtk.ListBox id="direct_members_list" />
#       <Gtk.Label id="no_direct_members_label" />
#     </Adw.PreferencesGroup>
#     <Adw.PreferencesGroup id="members_row_group">
#       <ButtonCountRow id="members_row" />
#     </Adw.PreferencesGroup>
#     <Adw.PreferencesGroup>
#       <ButtonCountRow />
#       <ButtonCountRow />
#       <ButtonCountRow />
#     </Adw.PreferencesGroup>
#     <Adw.PreferencesGroup id="notifications">
#       <CheckLoadingRow id="notifications_global_row" />
#       <CheckLoadingRow id="notifications_all_row" />
#       <CheckLoadingRow id="notifications_mentions_row" />
#       <CheckLoadingRow id="notifications_mute_row" />
#     </Adw.PreferencesGroup>
#     <Adw.PreferencesGroup id="addresses_group">
#       <Gtk.Button id="edit_addresses_button">
#         <Adw.ButtonContent />
#       </Gtk.Button>
#       <Gtk.Label id="no_addresses_label" />
#       <Gtk.ListBox>
#         <Adw.ButtonRow />
#       </Gtk.ListBox>
#     </Adw.PreferencesGroup>
#     <Adw.PreferencesGroup id="visibility_group">
#       <ButtonCountRow id="join_rule" />
#       <SwitchLoadingRow id="guest_access" />
#       <SwitchLoadingRow id="publish" />
#       <ButtonCountRow id="history_visibility" />
#     </Adw.PreferencesGroup>
#     <Adw.PreferencesGroup>
#       <CopyableRow id="room_id" />
#       <SwitchLoadingRow id="encryption" />
#       <ButtonCountRow />
#       <Adw.ActionRow id="room_version">
#         <LoadingButton id="upgrade_button" />
#       </Adw.ActionRow>
#       <Adw.ActionRow id="room_federated" />
#     </Adw.PreferencesGroup>
#   </Adw.PreferencesPage>
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
#                 <Gtk.TextBuffer slot="buffer" id="topic_buffer" />
#               </Gtk.TextView>
#             </Gtk.ScrolledWindow>
#             <LoadingButton id="save_topic_button" />
#           </Gtk.Box>
#         </Adw.PreferencesGroup>
#       </Adw.PreferencesPage>
#     </Adw.ToolbarView>
#   </Adw.NavigationPage>
#
# components/avatar/editable.blp
#
#   <Adw.Bin id="EditableAvatar">
#     <Gtk.Overlay>
#       <Gtk.Stack id="stack">
#         <Gtk.StackPage>
#           <Avatar slot="child" />
#         </Gtk.StackPage>
#         <Gtk.StackPage>
#           <Adw.Avatar slot="child" id="temp_avatar" />
#         </Gtk.StackPage>
#       </Gtk.Stack>
#       <Gtk.Image id="error_img" />
#       <Adw.Bin id="button_remove_bin">
#         <ActionButton id="button_remove" />
#       </Adw.Bin>
#       <Adw.Bin>
#         <ActionButton id="button_edit" />
#       </Adw.Bin>
#     </Gtk.Overlay>
#   </Adw.Bin>
#
# ── Build with ─────────────────────────────────────────────────────────────
#
# @reui/settings-3 — "General Settings Form with Per-Row Controls, Required and Pro
#   Badges". Adw.PreferencesGroup of ActionRows is this, row for row.
#
#   Adw.PreferencesPage              ->  page container; ui/card or reui/frame per group
#   Adw.PreferencesGroup             ->  ui/card with a heading
#   Adw.EntryRow (name, topic)       ->  ui/field + ui/input / ui/textarea
#   EditableAvatar                   ->  ui/avatar + file-upload
#   Adw.ActionRow (read-only facts)  ->  ui/item
#   row -> subpage chevrons          ->  drop them; the URL is the navigation now
#
# INSTALL, NOT IN EITHER REGISTRY -- reui lists file-upload on its components page but the
#   base-vega registry does not carry it; check the name before relying on it.
#
# general_page + edit_details_subpage in one: the fields are editable in place
# when our own power level allows it.

get "/" do
  room = Models::Matrix::Room.first(room_id: params["roomId"]) || halt(404, "matrix: no such room\n")
  me = Models::Matrix::Credential.first&.matrix_user_id.to_s

  render(
    "matrix/rooms/[roomId]/about",
    room: {
      roomId:         room.room_id,
      title:          room.title,
      avatarUrl:      room.avatar_url,
      topic:          room.topic,
      canonicalAlias: room.canonical_alias,
      encrypted:      room.encrypted,
      direct:         room.direct,
      memberCount:    room.joined_member_count.to_i,
      version:        room.room_version,
      createdBy:      room.creator,
      predecessor:    room.predecessor_room_id,
      successor:      room.successor_room_id,
      tombstoned:     room.tombstoned,
      joinRule:          room.join_rule,
      guestAccess:       room.guest_access,
      historyVisibility: room.history_visibility,
      notificationMode:  room.notification_mode,
    },
    can:  {
      name:   room.can_send_state?("m.room.name", me),
      topic:  room.can_send_state?("m.room.topic", me),
      avatar: room.can_send_state?("m.room.avatar", me),
    },
  )
end

post "/" do
  room_id = room_id!

  act! do
    case params["action"].to_s
    when "encrypt"
      Matrix::RoomActions.enable_encryption(room_id)
    when "guest-access"
      Matrix::RoomActions.set_guest_access(room_id, params["guest_access"].to_s)
    when "leave"
      Matrix::RoomActions.leave(room_id)
    when "forget"
      Matrix::RoomActions.forget(room_id)
    when "category"
      Matrix::RoomActions.set_category(room_id, params["category"].to_s)
    when "mark-unread"
      Matrix::RoomActions.mark_unread(room_id, params["unread"].to_s == "true")
    else
      halt(422, "matrix: unknown action\n")
    end
  end
end

__END__

import { Form, Head, Link } from "@inertiajs/react"
import { ArrowLeft, Hash, Lock, Users } from "lucide-react"

import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Alert, AlertDescription, AlertTitle } from "@/components/reui/alert"
import { Badge } from "@/components/reui/badge"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Item, ItemContent, ItemDescription, ItemTitle } from "@/components/ui/item"
import { Label } from "@/components/ui/label"
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group"
import { Switch } from "@/components/ui/switch"
import { ScrollArea } from "@/components/ui/scroll-area"
import { Textarea } from "@/components/ui/textarea"
import { ShellHeader } from "@/components/admin/slots"

type Room = {
  roomId: string
  title: string
  avatarUrl: string | null
  topic: string | null
  canonicalAlias: string | null
  encrypted: boolean
  direct: boolean
  memberCount: number
  version: string | null
  createdBy: string | null
  predecessor: string | null
  successor: string | null
  tombstoned: boolean
}

const initial = (name: string) => name.replace(/^[#!@]/, "").charAt(0).toUpperCase()

const NOTIFICATIONS = [
  { value: "global", label: "Use Global Setting" },
  { value: "all", label: "All Messages" },
  { value: "mentions", label: "Only Mentions and Keywords" },
  { value: "mute", label: "Disable Notifications" },
]

export default function MatrixRoomAbout({
  room,
  can,
}: {
  room: Room
  can: { name: boolean; topic: boolean; avatar: boolean }
}) {
  const encoded = encodeURIComponent(room.roomId)
  const readOnly = !can.name && !can.topic

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title={`About · ${room.title}`} />

      <ShellHeader>
        <Link href={`/matrix/rooms/${encoded}`} className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">Room Details</h1>
      </ShellHeader>

      <ScrollArea className="min-h-0 flex-1">
        <div className="mx-auto flex w-full max-w-2xl flex-col gap-4 p-6">
          {room.tombstoned && (
            <Alert variant="warning">
              <AlertTitle>This room has been upgraded</AlertTitle>
              <AlertDescription>
                A newer version replaced it. New messages belong in the successor.
              </AlertDescription>
            </Alert>
          )}

          <div className="flex flex-col items-center gap-3 py-2">
            <Avatar className="size-20">
              {room.avatarUrl && <AvatarImage src={room.avatarUrl} alt="" />}
              <AvatarFallback className="text-2xl">{initial(room.title)}</AvatarFallback>
            </Avatar>
            <div className="flex items-center gap-2">
              <h2 className="text-lg font-semibold">{room.title}</h2>
              {room.encrypted && <Lock className="size-4 text-muted-foreground" />}
            </div>
            {room.canonicalAlias && (
              <span className="text-sm text-muted-foreground">{room.canonicalAlias}</span>
            )}
          </div>

          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Edit Room Details</CardTitle>
            </CardHeader>
            <CardContent>
              <Form action={`/matrix/rooms/${encoded}/about`} method="post" className="flex flex-col gap-4">
                <div className="flex flex-col gap-2">
                  <Label htmlFor="name">Name</Label>
                  <Input id="name" name="name" defaultValue={room.title} disabled={!can.name} />
                </div>
                <div className="flex flex-col gap-2">
                  <Label htmlFor="topic">Topic</Label>
                  <Textarea
                    id="topic"
                    name="topic"
                    rows={3}
                    defaultValue={room.topic ?? ""}
                    disabled={!can.topic}
                  />
                </div>
                {readOnly ? (
                  <p className="text-xs text-muted-foreground">
                    You do not have permission to change these.
                  </p>
                ) : (
                  <Button type="submit" className="self-start">
                    Save
                  </Button>
                )}
              </Form>
            </CardContent>
          </Card>

          {/* Fractal's general_page is five groups: the history viewers, Notifications, Public
              Addresses, Access and Visibility, Advanced Information. Members and Permissions are
              reached from the header and the Access group respectively, not from a "Room" list. */}
          <Card>
            <CardContent className="flex flex-col gap-1 pt-6">
              <Item render={<Link href={`/matrix/rooms/${encoded}/media`} />}>
                <ItemContent>
                  <ItemTitle>Media</ItemTitle>
                </ItemContent>
              </Item>
              <Item render={<Link href={`/matrix/rooms/${encoded}/media/files`} />}>
                <ItemContent>
                  <ItemTitle>Files</ItemTitle>
                </ItemContent>
              </Item>
              <Item render={<Link href={`/matrix/rooms/${encoded}/media/audio`} />}>
                <ItemContent>
                  <ItemTitle>Audio</ItemTitle>
                </ItemContent>
              </Item>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Notifications</CardTitle>
            </CardHeader>
            <CardContent>
              <RadioGroup defaultValue={room.notificationMode ?? "global"} className="gap-3">
                {NOTIFICATIONS.map((option) => (
                  <div key={option.value} className="flex items-start gap-2">
                    <RadioGroupItem value={option.value} id={`n-${option.value}`} className="mt-0.5" />
                    <Label htmlFor={`n-${option.value}`} className="font-normal">
                      {option.label}
                    </Label>
                  </div>
                ))}
              </RadioGroup>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Public Addresses</CardTitle>
            </CardHeader>
            <CardContent className="flex flex-col gap-1">
              <Item render={<Link href={`/matrix/rooms/${encoded}/addresses`} />}>
                <ItemContent>
                  <ItemTitle>{room.canonicalAlias ?? "No published address"}</ItemTitle>
                </ItemContent>
                <Hash className="size-4 text-muted-foreground" />
              </Item>
              <Item render={<Link href={`/matrix/rooms/${encoded}/members`} />}>
                <ItemContent>
                  <ItemTitle>Copy Room Link</ItemTitle>
                  <ItemDescription>{room.memberCount} joined</ItemDescription>
                </ItemContent>
                <Users className="size-4 text-muted-foreground" />
              </Item>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Access and Visibility</CardTitle>
            </CardHeader>
            <CardContent className="flex flex-col gap-1">
              <Item render={<Link href={`/matrix/rooms/${encoded}/access`} />}>
                <ItemContent>
                  <ItemTitle>Who Can Join</ItemTitle>
                  <ItemDescription>{room.joinRule ?? "—"}</ItemDescription>
                </ItemContent>
              </Item>
              <div className="flex items-center justify-between gap-4 px-2 py-1.5">
                <div className="flex flex-col gap-0.5">
                  <Label htmlFor="guests" className="font-normal">
                    Allow Guests
                  </Label>
                  <span className="text-xs text-muted-foreground">
                    Guests are Matrix users without a registered account
                  </span>
                </div>
                <Switch id="guests" defaultChecked={room.guestAccess === "can_join"} />
              </div>
              <Item render={<Link href={`/matrix/rooms/${encoded}/visibility`} />}>
                <ItemContent>
                  <ItemTitle>Who Can Read History</ItemTitle>
                  <ItemDescription>{room.historyVisibility ?? "—"}</ItemDescription>
                </ItemContent>
              </Item>
              <Item render={<Link href={`/matrix/rooms/${encoded}/permissions`} />}>
                <ItemContent>
                  <ItemTitle>Permissions</ItemTitle>
                </ItemContent>
              </Item>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Advanced Information</CardTitle>
            </CardHeader>
            <CardContent className="flex flex-col gap-2 text-sm">
              <div className="flex items-center justify-between gap-4">
                <span className="text-muted-foreground">Matrix Room ID</span>
                <code className="truncate font-mono text-xs">{room.roomId}</code>
              </div>
              <div className="flex items-center justify-between gap-4">
                <span className="text-muted-foreground">Version</span>
                <Badge variant="secondary" size="sm">{room.version ?? "unknown"}</Badge>
              </div>
              {room.createdBy && (
                <div className="flex items-center justify-between gap-4">
                  <span className="text-muted-foreground">Created by</span>
                  <code className="truncate font-mono text-xs">{room.createdBy}</code>
                </div>
              )}
              <Button variant="outline" size="sm" className="mt-2 self-start" nativeButton={false} render={<Link href={`/matrix/rooms/${encoded}/upgrade`} />}>Upgrade room</Button>
            </CardContent>
          </Card>
        </div>
      </ScrollArea>
    </div>
  )
}
