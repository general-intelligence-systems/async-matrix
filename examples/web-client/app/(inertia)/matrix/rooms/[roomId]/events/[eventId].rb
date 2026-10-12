# frozen_string_literal: true

# /matrix/rooms/:roomId/events/:eventId — Event
#
# Fractal: room_history/event_actions/properties_dialog.rs (partially)
#
# NOT IMPLEMENTED.
#
# One event: the permalink target, and the view-source screen. Only possible
# now that matrix_events.raw exists -- the projection used to keep decrypted
# content and discard the envelope.
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
# session_view/room_history/event_actions/properties_dialog.blp
#
#   <ToastableDialog id="EventPropertiesDialog">
#     <Adw.NavigationView slot="child-content" id="navigation_view">
#       <Adw.NavigationPage>
#         <Adw.ToolbarView slot="child">
#           <Adw.HeaderBar />
#           <Gtk.ScrolledWindow slot="content">
#             <Adw.Clamp slot="child">
#               <Gtk.Box slot="child">
#                 <Gtk.Box>
#                   <Label />
#                   <Gtk.ListBox>
#                     <CopyableRow id="original_event_id_row" />
#                     <CopyableRow id="room_id_row" />
#                     <Adw.ActionRow id="sender_id_row">
#                       <Gtk.Button />
#                     </Adw.ActionRow>
#                     <CopyableRow id="original_timestamp_row" />
#                     <Adw.ButtonRow />
#                   </Gtk.ListBox>
#                 </Gtk.Box>
#                 <Gtk.Box>
#                   <Gtk.Label />
#                   <Gtk.ListBox>
#                     <CopyableRow id="edit_event_id_row" />
#                     <CopyableRow id="edit_timestamp_row" />
#                     <Adw.ButtonRow />
#                   </Gtk.ListBox>
#                 </Gtk.Box>
#               </Gtk.Box>
#             </Adw.Clamp>
#           </Gtk.ScrolledWindow>
#         </Adw.ToolbarView>
#       </Adw.NavigationPage>
#       <Adw.NavigationPage id="source_page">
#         <Adw.ToolbarView slot="child">
#           <Adw.HeaderBar>
#             <Gtk.Button />
#           </Adw.HeaderBar>
#           <Gtk.ScrolledWindow slot="content">
#             <GtkSource.View slot="child" id="source_view" />
#           </Gtk.ScrolledWindow>
#         </Adw.ToolbarView>
#       </Adw.NavigationPage>
#     </Adw.NavigationView>
#   </ToastableDialog>
#
# ── Build with ─────────────────────────────────────────────────────────────
#
# @reui/sheet-14 — "Audit event detail sheet with config diff, raw JSON and request
#   trace". Raw JSON with a diff is exactly the view-source screen, and the diff pane
#   is where an edit shows against its original.
#
#   PropertiesDialog             ->  ui/card sections, or ui/sheet if opened over the timeline
#   source / latest_edit_source  ->  reui/code-block, two panes — matrix_events.raw
#   CopyableRow                  ->  ui/item with a copy button
#   sender / timestamp           ->  ui/avatar + ui/tooltip
#
# INSTALL, reui registry: @reui/code-block
#
# One event: the permalink target and the view-source screen. Only possible
# because matrix_events.raw keeps the envelope the projection used to discard.
get "/" do
  room = matrix_room!

  event = Models::Matrix::Event.first(
    user_id: matrix_user_id, room_id: room[:room_id], event_id: params["eventId"].to_s,
  ) || halt(404, "matrix: no such event\n")

  render(
    "matrix/rooms/[roomId]/events/[eventId]",
    roomId:    room[:room_id],
    roomTitle: matrix_room_title(room),
    event:     matrix_event_json(event, []),
    source:    MultiJson.dump(event[:raw] || event[:content], pretty: true),
    unsigned:  MultiJson.dump(event[:unsigned] || {}, pretty: true),
  )
end

__END__

import { Head, Link } from "@inertiajs/react"
import { ArrowLeft } from "lucide-react"

import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Badge } from "@/components/reui/badge"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { ScrollArea } from "@/components/ui/scroll-area"
import { ShellHeader } from "@/components/admin/slots"

type Event = {
  eventId: string
  type: string
  sender: string
  senderName: string
  senderAvatar: string | null
  body: string | null
  ts: number
  edited: boolean
  redacted: boolean
  decryptionError: string | null
  stateKey: string | null
}

const initial = (name: string) => name.replace(/^[#!@]/, "").charAt(0).toUpperCase()

function Field({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-baseline justify-between gap-4 py-1">
      <span className="shrink-0 text-xs text-muted-foreground">{label}</span>
      <code className="truncate font-mono text-xs">{value}</code>
    </div>
  )
}

export default function MatrixEvent({
  roomId,
  roomTitle,
  event,
  source,
  unsigned,
}: {
  roomId: string
  roomTitle: string
  event: Event
  source: string
  unsigned: string
}) {
  const encoded = encodeURIComponent(roomId)

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title={`Event · ${roomTitle}`} />

      <ShellHeader>
        <Link href={`/matrix/rooms/${encoded}`} className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">Event</h1>
        <Badge variant="secondary" size="sm" className="ms-auto font-mono">
          {event.type}
        </Badge>
      </ShellHeader>

      <ScrollArea className="min-h-0 flex-1">
        <div className="mx-auto flex w-full max-w-3xl flex-col gap-4 p-6">
          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Event</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="mb-3 flex items-center gap-2">
                <Avatar className="size-8">
                  {event.senderAvatar && <AvatarImage src={event.senderAvatar} alt="" />}
                  <AvatarFallback className="text-[11px]">
                    {initial(event.senderName)}
                  </AvatarFallback>
                </Avatar>
                <div className="flex min-w-0 flex-col">
                  <span className="truncate text-sm font-medium">{event.senderName}</span>
                  <span className="truncate font-mono text-xs text-muted-foreground">
                    {event.sender}
                  </span>
                </div>
              </div>

              {event.body && (
                <p className="mb-3 rounded-md bg-muted px-3 py-2 text-sm whitespace-pre-wrap">
                  {event.body}
                </p>
              )}

              <Field label="Event ID" value={event.eventId} />
              <Field label="Room" value={roomId} />
              <Field label="Timestamp" value={new Date(event.ts).toLocaleString()} />
              {event.stateKey !== null && <Field label="State key" value={event.stateKey || '""'} />}
              {event.edited && <Field label="Edited" value="yes" />}
              {event.redacted && <Field label="Redacted" value="yes" />}
              {event.decryptionError && (
                <Field label="Decryption error" value={event.decryptionError} />
              )}
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Source</CardTitle>
            </CardHeader>
            <CardContent>
              <pre className="max-h-96 overflow-auto rounded-md bg-muted p-3 font-mono text-xs">
                {source}
              </pre>
            </CardContent>
          </Card>

          {unsigned !== "{}" && (
            <Card>
              <CardHeader>
                <CardTitle className="text-sm">Unsigned</CardTitle>
              </CardHeader>
              <CardContent>
                <pre className="max-h-64 overflow-auto rounded-md bg-muted p-3 font-mono text-xs">
                  {unsigned}
                </pre>
              </CardContent>
            </Card>
          )}
        </div>
      </ScrollArea>
    </div>
  )
}
