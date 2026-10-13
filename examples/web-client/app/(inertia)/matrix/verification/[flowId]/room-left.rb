# frozen_string_literal: true

# /matrix/verification/:flowId/room-left — Room left
#
# Fractal: identity_verification_view/room_left_page.{blp,rs}
#
# An in-room verification whose room is gone, which strands the flow.
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
# identity_verification_view/room_left_page.blp
#
#   <Adw.Bin id="IdentityVerificationRoomLeftPage">
#     <Gtk.ScrolledWindow>
#       <Adw.Clamp slot="child">
#         <Gtk.Box slot="child">
#           <Gtk.Label />
#           <Gtk.Label />
#           <Gtk.Button id="dismiss_btn" />
#         </Gtk.Box>
#       </Adw.Clamp>
#     </Gtk.ScrolledWindow>
#   </Adw.Bin>
#

get "/" do
  flow = verification_flow!

  render(
    "matrix/verification/[flowId]/room-left",
    flow: verification_row(flow),
    step: verification_step(flow),
  )
end

__END__

import { Head, Link } from "@inertiajs/react"

import { Alert, AlertDescription, AlertTitle } from "@/components/reui/alert"
import { Button } from "@/components/ui/button"
import { Act, Flow, Step } from "@/components/matrix/verification"

export default function MatrixVerificationRoomLeft({ flow }: { flow: Flow; step: string }) {
  return (
    <>
      <Head title="Room left" />
      <Step flow={flow} title="Room left">
        <Alert variant="warning">
          <AlertTitle>The room this ran in is gone</AlertTitle>
          <AlertDescription>
            An in-room verification carries its messages in the room's timeline, so leaving it
            strands the flow. {flow.roomId ? <code className="font-mono">{flow.roomId}</code> : null}
          </AlertDescription>
        </Alert>

        <p className="text-sm text-muted-foreground">
          Start again from a direct message, or verify the sessions themselves from encryption
          settings.
        </p>

        <div className="flex items-center gap-2">
          {flow.live && (
            <Act flow={flow} action="cancel" code="m.user_mismatch">
              Cancel
            </Act>
          )}
          <Button size="sm" variant="outline" render={<Link href="/matrix/settings/encryption/identity" />}>
            Encryption settings
          </Button>
        </div>
      </Step>
    </>
  )
}
