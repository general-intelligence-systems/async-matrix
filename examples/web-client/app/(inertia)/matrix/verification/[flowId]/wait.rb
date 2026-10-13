# frozen_string_literal: true

# /matrix/verification/:flowId/wait — Waiting for the other party
#
# Fractal: identity_verification_view/wait_for_other_page.{blp,rs}
#
# The request is sent and the other session has not answered yet.
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
# identity_verification_view/wait_for_other_page.blp
#
#   <Adw.Bin id="IdentityVerificationWaitForOtherPage">
#     <Gtk.ScrolledWindow id="scrolled_window">
#       <Adw.Clamp slot="child">
#         <Gtk.Box slot="child">
#           <Gtk.Label id="title" />
#           <Gtk.Label id="instructions" />
#           <Gtk.Label id="trust" />
#           <Gtk.Picture />
#           <Gtk.Label />
#           <LoadingButton id="cancel_btn" />
#         </Gtk.Box>
#       </Adw.Clamp>
#     </Gtk.ScrolledWindow>
#   </Adw.Bin>
#

get "/" do
  flow = verification_flow!

  render(
    "matrix/verification/[flowId]/wait",
    flow: verification_row(flow),
    step: verification_step(flow),
  )
end

__END__

import { Head } from "@inertiajs/react"

import { Alert, AlertDescription, AlertTitle } from "@/components/reui/alert"
import { Spinner } from "@/components/ui/spinner"
import { usePoll } from "@/hooks/use-poll"
import { Act, Flow, Stale, Step } from "@/components/matrix/verification"

export default function MatrixVerificationWait({ flow, step }: { flow: Flow; step: string }) {
  usePoll(flow.live, ["flow", "step"])

  return (
    <>
      <Head title="Waiting" />
      <Step flow={flow} title="Waiting for the other party">
        {step === "wait" ? null : <Stale flow={flow} />}

        <Alert>
          <AlertTitle className="flex items-center gap-2">
            <Spinner className="size-4" />
            Waiting for the other session
          </AlertTitle>
          <AlertDescription>
            The request is sent. Accept it on the other device and this page moves on by itself.
          </AlertDescription>
        </Alert>

        <Act flow={flow} action="cancel" code="user" variant="outline">
          Cancel
        </Act>
      </Step>
    </>
  )
}
