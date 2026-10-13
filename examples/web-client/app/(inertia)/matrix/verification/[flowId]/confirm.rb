# frozen_string_literal: true

# /matrix/verification/:flowId/confirm — Confirm QR code
#
# Fractal: identity_verification_view/confirm_qr_code_page.{blp,rs}
#
# We scanned theirs, and confirming is what signs it.
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
# identity_verification_view/confirm_qr_code_page.blp
#
#   <Adw.Bin id="IdentityVerificationConfirmQrCodePage">
#     <Gtk.ScrolledWindow id="scrolled_window">
#       <Adw.Clamp slot="child">
#         <Gtk.Box slot="child">
#           <Gtk.Label id="title" />
#           <Gtk.Picture />
#           <Gtk.Label id="question" />
#           <Adw.WrapBox>
#             <LoadingButton id="cancel_btn" />
#             <LoadingButton id="confirm_btn" />
#           </Adw.WrapBox>
#         </Gtk.Box>
#       </Adw.Clamp>
#     </Gtk.ScrolledWindow>
#   </Adw.Bin>
#

get "/" do
  flow = verification_flow!

  render(
    "matrix/verification/[flowId]/confirm",
    flow: verification_row(flow),
    step: verification_step(flow),
  )
end

__END__

import { Head } from "@inertiajs/react"

import { Alert, AlertDescription, AlertTitle } from "@/components/reui/alert"
import { usePoll } from "@/hooks/use-poll"
import { Act, Flow, Stale, Step } from "@/components/matrix/verification"

export default function MatrixVerificationConfirm({ flow, step }: { flow: Flow; step: string }) {
  usePoll(flow.live, ["flow", "step"])

  return (
    <>
      <Head title="Confirm QR code" />
      <Step flow={flow} title="Confirm QR code">
        {step === "confirm" ? null : <Stale flow={flow} />}

        <Alert>
          <AlertTitle>The code read correctly</AlertTitle>
          <AlertDescription>
            Confirming is what signs those keys. Wait for the other screen to say it is verified
            too.
          </AlertDescription>
        </Alert>

        <div className="flex items-center gap-2">
          <Act flow={flow} action="confirm_qr">
            Confirm
          </Act>
          <Act flow={flow} action="cancel" code="m.key_mismatch" variant="destructive">
            Something is wrong
          </Act>
        </div>
      </Step>
    </>
  )
}
