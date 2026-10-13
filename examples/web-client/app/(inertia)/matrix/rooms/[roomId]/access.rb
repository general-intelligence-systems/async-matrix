# frozen_string_literal: true

# /matrix/rooms/:roomId/access — Access
#
# Fractal: join_rule_subpage.blp + history_visibility_subpage.blp + guest access
#
# Who can join and who can read history: m.room.join_rules (including the
# restricted allow list), m.room.history_visibility, m.room.guest_access.
# Three subpages in Fractal, three sections here.
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
# session_view/room_details/join_rule_subpage.blp
#
#   <Adw.NavigationPage id="RoomDetailsJoinRuleSubpage">
#     <Adw.ToolbarView slot="child">
#       <Adw.HeaderBar>
#         <Gtk.Button />
#         <LoadingButton id="save_button" />
#       </Adw.HeaderBar>
#       <Gtk.ScrolledWindow slot="content" id="scrolled_window">
#         <Adw.Clamp slot="child">
#           <Gtk.Box slot="child">
#             <Gtk.Box id="info_box">
#               <Gtk.Image id="info_image" />
#               <Gtk.Label id="info_description" />
#             </Gtk.Box>
#             <Gtk.ListBox>
#               <CheckLoadingRow />
#               <CheckLoadingRow />
#             </Gtk.ListBox>
#             <Gtk.ListBox id="knock_box">
#               <Adw.SwitchRow id="knock_row" />
#             </Gtk.ListBox>
#           </Gtk.Box>
#         </Adw.Clamp>
#       </Gtk.ScrolledWindow>
#     </Adw.ToolbarView>
#   </Adw.NavigationPage>
#
# session_view/room_details/history_visibility_subpage.blp
#
#   <Adw.NavigationPage id="RoomDetailsHistoryVisibilitySubpage">
#     <Adw.ToolbarView slot="child">
#       <Adw.HeaderBar>
#         <Gtk.Button />
#         <LoadingButton id="save_button" />
#       </Adw.HeaderBar>
#       <Gtk.ScrolledWindow slot="content" id="scrolled_window">
#         <Adw.Clamp slot="child">
#           <Gtk.ListBox slot="child">
#             <CheckLoadingRow />
#             <CheckLoadingRow />
#             <CheckLoadingRow />
#             <CheckLoadingRow />
#           </Gtk.ListBox>
#         </Adw.Clamp>
#       </Gtk.ScrolledWindow>
#     </Adw.ToolbarView>
#   </Adw.NavigationPage>
#
# ── Build with ─────────────────────────────────────────────────────────────
#
# @reui/settings-10 — "Workspace security settings in Frame cards mixing toggles, a
#   timeout select, and plan-tier badges". Three Frame cards, one per state event.
#
#   join_rule (5 values)           ->  ui/radio-group inside a card — mutually exclusive, so not a
#                                       select
#   restricted allow list          ->  ui/item rows naming the spaces that grant access
#   history_visibility (4 values)  ->  ui/radio-group
#   guest_access                   ->  ui/switch
#   Adw.PreferencesGroup           ->  reui/frame — already vendored
#
# INSTALL, plain shadcn: radio-group
#
# join_rule + history_visibility + guest_access. Three state events, three
# cards -- Fractal pushes three subpages for the same thing.

get "/" do
  room = Models::Matrix::Room.first(room_id: params["roomId"]) || halt(404, "matrix: no such room\n")

  render(
    "matrix/rooms/[roomId]/access",
    roomId:    room.room_id,
    roomTitle: room.title,
    joinRule:  room.join_rule || "invite",
    allow:     room.join_rule_allow.map{|entry| entry["room_id"]}.compact,
    history:   room.history_visibility || "shared",
    guests:    room.guest_access == "can_join",
  )
end

post "/" do
  act! do
    Matrix::RoomActions.set_join_rule(room_id!, params["join_rule"].to_s)
  end
end

__END__

import { Form, Head, Link } from "@inertiajs/react"
import { ArrowLeft } from "lucide-react"

import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Label } from "@/components/ui/label"
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group"
import { ScrollArea } from "@/components/ui/scroll-area"
import { Switch } from "@/components/ui/switch"
import { ShellHeader } from "@/components/admin/slots"

// The spec's five join rules. knock_restricted is omitted: it needs a space
// list to mean anything and the UI for that belongs with `restricted`.
const JOIN_RULES = [
  { value: "invite", label: "Only Invited Users" },
  { value: "public", label: "Any Registered User" },
]

const HISTORY = [
  { value: "world_readable", label: "Anyone, even if they are not in the room" },
  { value: "shared", label: "Members only, since this option was selected" },
  { value: "invited", label: "Members only, since they were invited" },
  { value: "joined", label: "Members only, since they joined the room" },
]

function Choice({
  name,
  options,
  value,
}: {
  name: string
  options: { value: string; label: string; hint?: string }[]
  value: string
}) {
  return (
    <RadioGroup name={name} defaultValue={value} className="gap-3">
      {options.map((option) => (
        <div key={option.value} className="flex items-start gap-3">
          <RadioGroupItem value={option.value} id={`${name}-${option.value}`} className="mt-0.5" />
          <div className="flex flex-col gap-0.5">
            <Label htmlFor={`${name}-${option.value}`} className="font-normal">
              {option.label}
            </Label>
            {option.hint && (
              <span className="text-xs text-muted-foreground">{option.hint}</span>
            )}
          </div>
        </div>
      ))}
    </RadioGroup>
  )
}

export default function MatrixRoomAccess({
  roomId,
  roomTitle,
  joinRule,
  allow,
  history,
  guests,
}: {
  roomId: string
  roomTitle: string
  joinRule: string
  allow: string[]
  history: string
  guests: boolean
}) {
  const encoded = encodeURIComponent(roomId)

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title={`Access · ${roomTitle}`} />

      <ShellHeader>
        <Link href={`/matrix/rooms/${encoded}/about`} className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">Who Can Join</h1>
      </ShellHeader>

      <ScrollArea className="min-h-0 flex-1">
        <Form
          action={`/matrix/rooms/${encoded}/access`}
          method="post"
          className="mx-auto flex w-full max-w-2xl flex-col gap-4 p-6"
        >
          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Who Can Join</CardTitle>
              <CardDescription>m.room.join_rules</CardDescription>
            </CardHeader>
            <CardContent className="flex flex-col gap-4">
              <Choice name="join_rule" options={JOIN_RULES} value={joinRule} />
              {allow.length > 0 && (
                <div className="rounded-md border p-3">
                  <p className="mb-2 text-xs font-medium text-muted-foreground">
                    Members of these spaces can join
                  </p>
                  <ul className="flex flex-col gap-1">
                    {allow.map((space) => (
                      <li key={space} className="truncate font-mono text-xs">
                        {space}
                      </li>
                    ))}
                  </ul>
                </div>
              )}

              {/* Fractal keeps knocking as a switch beside the two rules rather than a third
                  rule, because m.room.join_rules spells it as its own value. */}
              <div className="flex items-center justify-between gap-4 border-t pt-4">
                <Label htmlFor="knock" className="font-normal">
                  Allow Invite Requests
                </Label>
                <Switch id="knock" name="knock" value="true" defaultChecked={joinRule === "knock"} />
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Who Can Read History</CardTitle>
              <CardDescription>m.room.history_visibility</CardDescription>
            </CardHeader>
            <CardContent>
              <Choice name="history_visibility" options={HISTORY} value={history} />
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Allow Guests</CardTitle>
              <CardDescription>m.room.guest_access</CardDescription>
            </CardHeader>
            <CardContent className="flex items-center justify-between gap-4">
              <Label htmlFor="guest_access" className="font-normal">
                Allow guest accounts to join
              </Label>
              <Switch id="guest_access" name="guest_access" defaultChecked={guests} />
            </CardContent>
          </Card>

          <Button type="submit" className="self-start">
            Save
          </Button>
        </Form>
      </ScrollArea>
    </div>
  )
}
