# frozen_string_literal: true

# /matrix/rooms/:roomId/invite — Invite people
#
# Fractal: room_details/invite_subpage/
#
# Invite people TO this room. Not to be confused with the invite you received,
# which is a rendering of rooms/[roomId].rb rather than a route.
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
# session_view/room_details/invite_subpage/mod.blp
#
#   <Adw.NavigationPage id="RoomDetailsInviteSubpage">
#     <Adw.ToolbarView slot="child">
#       <Adw.HeaderBar>
#         <Gtk.Button id="cancel_button" />
#         <LoadingButton id="invite_button" />
#       </Adw.HeaderBar>
#       <Adw.Clamp>
#         <PillSearchEntry id="search_entry" />
#       </Adw.Clamp>
#       <Gtk.Stack slot="content" id="stack">
#         <Gtk.StackPage>
#           <Adw.StatusPage slot="child" id="no_search_page" />
#         </Gtk.StackPage>
#         <Gtk.StackPage>
#           <Gtk.ScrolledWindow slot="child" id="matching_page">
#             <Adw.ClampScrollable slot="child">
#               <Gtk.ListView slot="child" id="list_view">
#                 <Gtk.BuilderListItemFactory slot="factory">
#                   <RoomDetailsInviteRow slot="child" id="row" />
#                 </Gtk.BuilderListItemFactory>
#               </Gtk.ListView>
#             </Adw.ClampScrollable>
#           </Gtk.ScrolledWindow>
#         </Gtk.StackPage>
#         <Gtk.StackPage>
#           <Adw.StatusPage slot="child" id="no_matching_page" />
#         </Gtk.StackPage>
#         <Gtk.StackPage>
#           <Adw.StatusPage slot="child" id="error_page" />
#         </Gtk.StackPage>
#         <Gtk.StackPage>
#           <Adw.Spinner slot="child" />
#         </Gtk.StackPage>
#       </Gtk.Stack>
#     </Adw.ToolbarView>
#   </Adw.NavigationPage>
#
# session_view/room_details/invite_subpage/row.blp
#
#   <Adw.Bin id="RoomDetailsInviteRow">
#     <Gtk.Box slot="child" id="header">
#       <Avatar />
#       <Gtk.Box>
#         <Gtk.Label id="subtitle" />
#       </Gtk.Box>
#       <Gtk.CheckButton id="check_button" />
#       <Gtk.Label />
#     </Gtk.Box>
#   </Adw.Bin>
#
# ── Build with ─────────────────────────────────────────────────────────────
#
# @reui/dialog-8 — "Multi-row collaborator invite dialog with per-row email field and
#   role select", or @reui/wizard-5 — "Three step team invitation wizard with per-row
#   role assignment and pre-send review" if you want the confirm step.
#
#   InviteSubpage search      ->  reui/autocomplete — /user_directory/search
#   selected as pills         ->  ui/badge chips, removable
#   InviteRow                 ->  ui/item + ui/avatar
#   per-user failure on send  ->  reui/alert — invites fail individually, so report individually
#
# INSTALL, reui registry: @reui/autocomplete
#
# Invite people TO this room. Not the invite you received -- that is a
# rendering of rooms/[roomId].rb.

get "/" do
  room = Models::Matrix::Room.first(room_id: params["roomId"]) || halt(404, "matrix: no such room\n")

  render(
    "matrix/rooms/[roomId]/invite",
    roomId:    room.room_id,
    roomTitle: room.title,
    # Already in the room, so the view can mark them rather than offer them.
    existing:  room.members.exclude(membership: %w[leave ban]).select_map(:member_id),
  )
end

post "/" do
  act! do
    Matrix::RoomActions.invite(room_id!, params["user_id"].to_s, reason: params["reason"])
  end
end

__END__

import { Form, Head, Link } from "@inertiajs/react"
import { useState } from "react"
import { ArrowLeft, Plus, X } from "lucide-react"

import { Badge } from "@/components/reui/badge"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import {
  InputGroup,
  InputGroupAddon,
  InputGroupButton,
  InputGroupInput,
} from "@/components/ui/input-group"
import { ScrollArea } from "@/components/ui/scroll-area"
import { ShellHeader } from "@/components/admin/slots"

export default function MatrixRoomInvite({
  roomId,
  roomTitle,
  existing,
}: {
  roomId: string
  roomTitle: string
  existing: string[]
}) {
  const encoded = encodeURIComponent(roomId)
  const [draft, setDraft] = useState("")
  const [invitees, setInvitees] = useState<string[]>([])

  const add = () => {
    const id = draft.trim()
    // A Matrix id is @localpart:server. Anything else is a typo, and inviting
    // a typo silently does nothing on the server.
    if (!/^@[^:]+:.+/.test(id) || invitees.includes(id) || existing.includes(id)) return
    setInvitees([...invitees, id])
    setDraft("")
  }

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title={`Invite · ${roomTitle}`} />

      <ShellHeader>
        <Link href={`/matrix/rooms/${encoded}/members`} className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">Invite to {roomTitle}</h1>
      </ShellHeader>

      <ScrollArea className="min-h-0 flex-1">
        <div className="mx-auto flex w-full max-w-2xl flex-col gap-4 p-6">
          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Search</CardTitle>
              <CardDescription>Full Matrix IDs, like @alice:example.org.</CardDescription>
            </CardHeader>
            <CardContent className="flex flex-col gap-3">
              <InputGroup>
                <InputGroupAddon>@</InputGroupAddon>
                <InputGroupInput
                  value={draft}
                  onChange={(event) => setDraft(event.target.value)}
                  onKeyDown={(event) => {
                    if (event.key === "Enter") {
                      event.preventDefault()
                      add()
                    }
                  }}
                  placeholder="alice:example.org"
                />
                <InputGroupAddon align="inline-end">
                  <InputGroupButton size="xs" onClick={add} type="button">
                    <Plus className="size-3.5" />
                    Add
                  </InputGroupButton>
                </InputGroupAddon>
              </InputGroup>

              {invitees.length > 0 && (
                <div className="flex flex-wrap gap-1.5">
                  {invitees.map((id) => (
                    <Badge key={id} variant="secondary" className="gap-1">
                      <span className="font-mono">{id}</span>
                      <button
                        type="button"
                        onClick={() => setInvitees(invitees.filter((other) => other !== id))}
                        aria-label={`Remove ${id}`}
                      >
                        <X className="size-3" />
                      </button>
                    </Badge>
                  ))}
                </div>
              )}

              <Form action={`/matrix/rooms/${encoded}/invite`} method="post">
                {invitees.map((id) => (
                  <input key={id} type="hidden" name="invitees[]" value={id} />
                ))}
                <Button type="submit" disabled={invitees.length === 0}>
                  Invite {invitees.length > 0 && invitees.length}
                </Button>
              </Form>

              {/* Invites fail one at a time -- a blocked user or a dead server
                  fails alone -- so the result has to be reported per person. */}
              <p className="text-xs text-muted-foreground">
                Each invite is sent separately and can fail on its own.
              </p>
            </CardContent>
          </Card>
        </div>
      </ScrollArea>
    </div>
  )
}
