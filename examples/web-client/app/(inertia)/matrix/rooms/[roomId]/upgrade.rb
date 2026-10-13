# frozen_string_literal: true

# /matrix/rooms/:roomId/upgrade — Upgrade
#
# Fractal: room_details/upgrade_dialog/
#
# Upgrade the room to a newer version, which tombstones this one and creates
# its successor (matrix_rooms.successor_room_id / predecessor_room_id).
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
# session_view/room_details/upgrade_dialog/mod.blp
#
#   <Adw.Dialog id="RoomDetailsUpgradeDialog">
#     <Gtk.WindowHandle slot="child">
#       <Gtk.Box slot="child">
#         <Gtk.ScrolledWindow>
#           <Gtk.Box slot="child">
#             <Adw.Bin>
#               <Gtk.Label />
#             </Adw.Bin>
#             <Gtk.Label id="description" />
#             <Gtk.ListBox>
#               <Adw.ComboRow id="version_combo" />
#             </Gtk.ListBox>
#             <Gtk.Label id="invite_only_warning_label" />
#             <Gtk.Label id="creators_warning_label" />
#           </Gtk.Box>
#         </Gtk.ScrolledWindow>
#         <Adw.WrapBox>
#           <Gtk.Button />
#           <Gtk.Button />
#         </Adw.WrapBox>
#       </Gtk.Box>
#     </Gtk.WindowHandle>
#   </Adw.Dialog>
#
# ── Build with ─────────────────────────────────────────────────────────────
#
# @reui/dialog-3 — "Plan cancellation dialog with multi-select reason checkboxes,
#   feedback textarea, and warning banner". Taken for its SHAPE, not its content: a
#   destructive, irreversible action that has to explain itself before it runs.
#
#   UpgradeDialog   ->  ui/alert-dialog — tombstoning a room cannot be undone
#   version select  ->  ui/select
#   consequences    ->  reui/alert
#

get "/" do
  room = Models::Matrix::Room.first(room_id: params["roomId"]) || halt(404, "matrix: no such room\n")

  render(
    "matrix/rooms/[roomId]/upgrade",
    roomId:    room.room_id,
    roomTitle: room.title,
    version:   room.room_version || "unknown",
    successor: room.successor_room_id,
  )
end

post "/" do
  act! do
    Matrix::RoomActions.upgrade(room_id!, params.fetch("new_version", "11").to_s)
  end
end

__END__

import { Form, Head, Link } from "@inertiajs/react"
import { ArrowLeft } from "lucide-react"

import { Alert, AlertDescription, AlertTitle } from "@/components/reui/alert"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Label } from "@/components/ui/label"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import { ShellHeader } from "@/components/admin/slots"

export default function MatrixRoomUpgrade({
  roomId,
  roomTitle,
  version,
  successor,
}: {
  roomId: string
  roomTitle: string
  version: string
  successor: string | null
}) {
  const encoded = encodeURIComponent(roomId)

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title={`Upgrade · ${roomTitle}`} />

      <ShellHeader>
        <Link href={`/matrix/rooms/${encoded}/about`} className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">Upgrade room</h1>
      </ShellHeader>

      <div className="mx-auto flex w-full max-w-xl flex-col gap-4 p-6">
        {successor ? (
          <Alert variant="warning">
            <AlertTitle>Already upgraded</AlertTitle>
            <AlertDescription>
              This room was replaced. Its successor is{" "}
              <Link
                href={`/matrix/rooms/${encodeURIComponent(successor)}`}
                className="font-mono underline"
              >
                {successor}
              </Link>
              .
            </AlertDescription>
          </Alert>
        ) : (
          <>
            {/* Irreversible: the old room is tombstoned and stays read-only
                forever. Said before the control, not after it. */}
            <Alert variant="destructive">
              <AlertTitle>This cannot be undone</AlertTitle>
              <AlertDescription>
                Upgrading creates a new room and closes this one. The history stays here and is
                not copied across, and everyone has to join the replacement.
              </AlertDescription>
            </Alert>

            <Card>
              <CardHeader>
                <CardTitle className="text-sm">New version</CardTitle>
                <CardDescription>This room is on version {version}.</CardDescription>
              </CardHeader>
              <CardContent>
                <Form
                  action={`/matrix/rooms/${encoded}/upgrade`}
                  method="post"
                  className="flex flex-col gap-4"
                >
                  <div className="flex flex-col gap-2">
                    <Label htmlFor="version">Upgrade to</Label>
                    <Select name="new_version" defaultValue="11">
                      <SelectTrigger id="version">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        {["9", "10", "11", "12"].map((option) => (
                          <SelectItem key={option} value={option}>
                            Version {option}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>
                  <Button type="submit" variant="destructive" className="self-start">
                    Upgrade room
                  </Button>
                </Form>
              </CardContent>
            </Card>
          </>
        )}
      </div>
    </div>
  )
}
