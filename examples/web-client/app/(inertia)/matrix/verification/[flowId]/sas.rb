# frozen_string_literal: true

# /matrix/verification/:flowId/sas — Compare emoji
#
# Fractal: identity_verification_view/sas_page.{blp,rs} + sas_emoji.blp
#
# The seven emoji both sides derive from the shared secret, which match or they do not.
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
# identity_verification_view/sas_page.blp
#
#   <Adw.Bin id="IdentityVerificationSasPage">
#     <Gtk.ScrolledWindow id="scrolled_window">
#       <Adw.Clamp slot="child">
#         <Gtk.Box slot="child">
#           <Gtk.Label id="title" />
#           <Gtk.Label id="instructions" />
#           <Gtk.Box id="row_1" />
#           <Gtk.Box id="row_2" />
#           <Adw.WrapBox>
#             <LoadingButton id="mismatch_btn" />
#             <LoadingButton id="match_btn" />
#           </Adw.WrapBox>
#         </Gtk.Box>
#       </Adw.Clamp>
#     </Gtk.ScrolledWindow>
#   </Adw.Bin>
#

get "/" do
  flow = verification_flow!

  render(
    "matrix/verification/[flowId]/sas",
    flow: verification_row(flow),
    step: verification_step(flow),
  )
end

__END__

import { Head } from "@inertiajs/react"

import { Alert, AlertDescription, AlertTitle } from "@/components/reui/alert"
import { usePoll } from "@/hooks/use-poll"
import { Act, Flow, Stale, Step } from "@/components/matrix/verification"

export default function MatrixVerificationSas({ flow, step }: { flow: Flow; step: string }) {
  usePoll(flow.live, ["flow", "step"])

  return (
    <>
      <Head title="Compare emoji" />
      <Step flow={flow} title="Compare emoji">
        {step === "sas" ? null : <Stale flow={flow} />}

        <Alert>
          <AlertTitle>Do these appear on the other screen too?</AlertTitle>
          <AlertDescription>
            In the same order. If anything differs, say they do not match: that is what an
            interception looks like.
          </AlertDescription>
        </Alert>

        <div className="grid grid-cols-4 gap-3 rounded-md border p-4">
          {flow.emoji.map((item, index) => (
            <div key={`${item.symbol}-${index}`} className="flex flex-col items-center gap-1">
              <span className="text-3xl leading-none">{item.symbol}</span>
              <span className="text-center text-[11px] text-muted-foreground">{item.name}</span>
            </div>
          ))}
        </div>

        {flow.decimals.length > 0 && (
          <p className="text-center font-mono text-sm text-muted-foreground">
            {flow.decimals.join(" · ")}
          </p>
        )}

        <div className="flex items-center gap-2">
          <Act flow={flow} action="confirm">
            They match
          </Act>
          <Act flow={flow} action="cancel" code="m.mismatched_sas" variant="destructive">
            They do not match
          </Act>
        </div>
      </Step>
    </>
  )
}
