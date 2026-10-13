# frozen_string_literal: true

# /matrix/verification/:flowId/scanned — QR code scanned
#
# Fractal: identity_verification_view/qr_code_scanned_page.{blp,rs}
#
# The other side scanned ours and is asking us to confirm it.
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
# identity_verification_view/qr_code_scanned_page.blp
#
#   <Adw.Bin id="IdentityVerificationQrCodeScannedPage">
#     <Gtk.ScrolledWindow id="scrolled_window">
#       <Adw.Clamp slot="child">
#         <Gtk.Box slot="child">
#           <Gtk.Label id="title" />
#           <Gtk.Picture />
#           <Gtk.Label id="message" />
#           <LoadingButton id="cancel_btn" />
#         </Gtk.Box>
#       </Adw.Clamp>
#     </Gtk.ScrolledWindow>
#   </Adw.Bin>
#

get "/" do
  flow = verification_flow!

  render(
    "matrix/verification/[flowId]/scanned",
    flow: verification_row(flow),
    step: verification_step(flow),
  )
end

__END__

import { Head } from "@inertiajs/react"

import { Alert, AlertDescription, AlertTitle } from "@/components/reui/alert"
import { usePoll } from "@/hooks/use-poll"
import { Act, Flow, Stale, Step } from "@/components/matrix/verification"

export default function MatrixVerificationScanned({ flow, step }: { flow: Flow; step: string }) {
  usePoll(flow.live, ["flow", "step"])

  return (
    <>
      <Head title="QR code scanned" />
      <Step flow={flow} title="QR code scanned">
        {step === "scanned" ? null : <Stale flow={flow} />}

        <Alert>
          <AlertTitle>The other side scanned this code</AlertTitle>
          <AlertDescription>
            It sent back the secret the code carried, which only something that saw the screen could
            know. Confirm if that device is the one in front of you.
          </AlertDescription>
        </Alert>

        <div className="flex items-center gap-2">
          <Act flow={flow} action="confirm_qr">
            Confirm
          </Act>
          <Act flow={flow} action="cancel" code="m.user_mismatch" variant="destructive">
            That was not me
          </Act>
        </div>
      </Step>
    </>
  )
}
