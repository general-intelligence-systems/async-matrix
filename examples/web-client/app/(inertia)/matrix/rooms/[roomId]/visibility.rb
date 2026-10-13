# frozen_string_literal: true

# /matrix/rooms/:roomId/visibility — History visibility
#
# Fractal: room_details/history_visibility_subpage.{blp,rs}
#
# m.room.history_visibility: how far back a new member can read. Separate from the join rule, which is /access.
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
# session_view/room_details/history_visibility_subpage.blp
#
#   <Adw.NavigationPage id="RoomDetailsHistoryVisibilitySubpage">
#     <Adw.ToolbarView slot="child">
#       <Adw.HeaderBar>
#         <Gtk.Button />
#         <LoadingButton id="save_button" />
#       </Adw.HeaderBar>
#       <Gtk.ScrolledWindow id="scrolled_window" slot="content">
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

get "/" do
  room = Models::Matrix::Room.first(room_id: params["roomId"]) || halt(404, "matrix: no such room\n")
  me = Models::Matrix::Credential.first&.matrix_user_id.to_s

  render(
    "matrix/rooms/[roomId]/visibility",
    roomId:    room.room_id,
    roomTitle: room.title,
    value:     room.history_visibility || "shared",
    editable:  room.can_send_state?("m.room.history_visibility", me),
  )
end

post "/" do
  act! do
    Matrix::RoomActions.set_history_visibility(room_id!, params["history_visibility"].to_s)
  end
end

__END__

import { Form, Head, Link } from "@inertiajs/react"
import { ArrowLeft } from "lucide-react"

import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { Label } from "@/components/ui/label"
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group"
import { ShellHeader } from "@/components/admin/slots"

// history_visibility_subpage.blp, verbatim and in its order.
const OPTIONS = [
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
  options: { value: string; label: string }[]
  value: string
}) {
  return (
    <RadioGroup name={name} defaultValue={value} className="gap-3">
      {options.map((option) => (
        <div key={option.value} className="flex items-start gap-2">
          <RadioGroupItem value={option.value} id={`${name}-${option.value}`} className="mt-0.5" />
          <Label htmlFor={`${name}-${option.value}`} className="font-normal">
            {option.label}
          </Label>
        </div>
      ))}
    </RadioGroup>
  )
}

export default function MatrixRoomVisibility({
  roomId,
  roomTitle,
  value,
  editable,
}: {
  roomId: string
  roomTitle: string
  value: string
  editable: boolean
}) {
  const encoded = encodeURIComponent(roomId)

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title={`Who Can Read History · ${roomTitle}`} />

      <ShellHeader>
        <Link href={`/matrix/rooms/${encoded}/about`} className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">Who Can Read History</h1>
      </ShellHeader>

      <div className="mx-auto flex w-full max-w-xl flex-col gap-4 p-6">
        <Card>
          <CardContent className="pt-6">
            <Form
              action={`/matrix/rooms/${encoded}/visibility`}
              method="post"
              className="flex flex-col gap-4"
            >
              {({ processing }) => (
                <>
                  <Choice name="history_visibility" options={OPTIONS} value={value} />
                  <Button type="submit" className="self-start" disabled={processing || !editable}>
                    Save
                  </Button>
                </>
              )}
            </Form>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
