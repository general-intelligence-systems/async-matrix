# frozen_string_literal: true

# /matrix/verification/:flowId/cancelled — Cancelled
#
# Fractal: identity_verification_view/cancelled_page.{blp,rs}
#
# Either side cancelled, with the m.key.verification.cancel code as the reason.
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
# identity_verification_view/cancelled_page.blp
#
#   <Adw.Bin id="IdentityVerificationCancelledPage">
#     <Gtk.ScrolledWindow id="scrolled_window">
#       <Adw.Clamp slot="child">
#         <Gtk.Box slot="child">
#           <Gtk.Label id="title" />
#           <Gtk.Label id="message" />
#           <Adw.WrapBox>
#             <LoadingButton id="dismiss_btn" />
#             <LoadingButton id="try_again_btn" />
#           </Adw.WrapBox>
#         </Gtk.Box>
#       </Adw.Clamp>
#     </Gtk.ScrolledWindow>
#   </Adw.Bin>
#

get "/" do
  flow = verification_flow!

  render(
    "matrix/verification/[flowId]/cancelled",
    flow: verification_row(flow),
    step: verification_step(flow),
  )
end

__END__

import { Head, Link } from "@inertiajs/react"
import { ShieldX } from "lucide-react"

import { Alert, AlertDescription, AlertTitle } from "@/components/reui/alert"
import { Button } from "@/components/ui/button"
import { Flow, Step } from "@/components/matrix/verification"

export default function MatrixVerificationCancelled({ flow }: { flow: Flow; step: string }) {
  return (
    <>
      <Head title="Cancelled" />
      <Step flow={flow} title="Cancelled">
        <div className="flex flex-col items-center gap-2 py-4">
          <ShieldX className="size-10 text-muted-foreground" />
          <h2 className="text-center text-xl font-semibold tracking-tight">
            Verification Cancelled
          </h2>
        </div>

        <Alert variant={flow.cancelCode === "m.mismatched_sas" ? "destructive" : "warning"}>
          <AlertTitle>{flow.cancelReason || "It was cancelled"}</AlertTitle>
          <AlertDescription>
            {flow.cancelCode === "m.mismatched_sas" ? (
              <>
                Emoji that do not match is what an interception looks like. Nothing was signed, and
                it is worth asking the other person over a channel you trust.
              </>
            ) : (
              <>
                Nothing was signed. Code <code>{flow.cancelCode || "unknown"}</code>.
              </>
            )}
          </AlertDescription>
        </Alert>

        <div className="flex items-center gap-2">
          <Button size="sm" variant="outline" render={<Link href="/matrix/settings/encryption/identity" />}>
            Try again
          </Button>
          <Button size="sm" variant="ghost" render={<Link href="/matrix/verification" />}>
            Back
          </Button>
        </div>
      </Step>
    </>
  )
}
