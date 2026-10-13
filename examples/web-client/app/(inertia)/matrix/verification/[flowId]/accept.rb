# frozen_string_literal: true

# /matrix/verification/:flowId/accept — Accept request
#
# Fractal: identity_verification_view/accept_request_page.{blp,rs}
#
# An incoming verification request, to accept or decline.
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
# identity_verification_view/accept_request_page.blp
#
#   <Adw.Bin id="IdentityVerificationAcceptRequestPage">
#     <Gtk.ScrolledWindow id="scrolled_window">
#       <Adw.Clamp slot="child">
#         <Gtk.Box slot="child">
#           <Gtk.Label id="title" />
#           <Gtk.Label id="instructions" />
#           <Gtk.Picture />
#           <Adw.WrapBox>
#             <LoadingButton id="decline_btn" />
#             <LoadingButton id="accept_btn" />
#           </Adw.WrapBox>
#         </Gtk.Box>
#       </Adw.Clamp>
#     </Gtk.ScrolledWindow>
#   </Adw.Bin>
#

get "/" do
  flow = verification_flow!

  render(
    "matrix/verification/[flowId]/accept",
    flow: verification_row(flow),
    step: verification_step(flow),
  )
end

__END__

import { Head } from "@inertiajs/react"

import { Alert, AlertDescription, AlertTitle } from "@/components/reui/alert"
import { usePoll } from "@/hooks/use-poll"
import { Act, Flow, Stale, Step } from "@/components/matrix/verification"

export default function MatrixVerificationAccept({ flow, step }: { flow: Flow; step: string }) {
  usePoll(flow.live, ["flow", "step"])

  return (
    <>
      <Head title="Accept request" />
      <Step flow={flow} title="Accept request">
        {step === "accept" ? null : <Stale flow={flow} />}

        <Alert>
          <AlertTitle>
            {flow.own ? "Another of your sessions wants to verify" : "Someone wants to verify you"}
          </AlertTitle>
          <AlertDescription>
            {flow.own
              ? "Accepting hands that session the keys it needs to read your encrypted messages."
              : "Accepting lets you both compare a short code, after which your clients trust each other's keys."}
          </AlertDescription>
        </Alert>

        <div className="flex items-center gap-2">
          <Act flow={flow} action="accept">
            Accept
          </Act>
          <Act flow={flow} action="cancel" code="user" variant="outline">
            Decline
          </Act>
        </div>
      </Step>
    </>
  )
}
