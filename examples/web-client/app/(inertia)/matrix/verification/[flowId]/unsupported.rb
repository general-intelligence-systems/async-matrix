# frozen_string_literal: true

# /matrix/verification/:flowId/unsupported — No supported methods
#
# Fractal: identity_verification_view/no_supported_methods_page.{blp,rs}
#
# Nothing both sides can do: no camera here, no emoji there.
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
# identity_verification_view/no_supported_methods_page.blp
#
#   <Adw.Bin id="IdentityVerificationNoSupportedMethodsPage">
#     <Gtk.ScrolledWindow id="scrolled_window">
#       <Adw.Clamp slot="child">
#         <Gtk.Box slot="child">
#           <Gtk.Label id="title" />
#           <Gtk.Label id="message" />
#           <Gtk.Label id="instructions" />
#           <LoadingButton id="cancel_btn" />
#         </Gtk.Box>
#       </Adw.Clamp>
#     </Gtk.ScrolledWindow>
#   </Adw.Bin>
#

get "/" do
  flow = verification_flow!

  render(
    "matrix/verification/[flowId]/unsupported",
    flow: verification_row(flow),
    step: verification_step(flow),
    offered: Matrix::Verification.offered(flow),
  )
end

__END__

import { Head, Link } from "@inertiajs/react"

import { Alert, AlertDescription, AlertTitle } from "@/components/reui/alert"
import { Button } from "@/components/ui/button"
import { Act, Flow, Step } from "@/components/matrix/verification"

const NAMES: Record<string, string> = {
  "m.sas.v1": "Compare emoji",
  "m.qr_code.show.v1": "Show a QR code",
  "m.qr_code.scan.v1": "Scan a QR code",
  "m.reciprocate.v1": "Reciprocate a scanned code",
}

export default function MatrixVerificationUnsupported({
  flow,
  offered,
}: {
  flow: Flow
  step: string
  offered: string[]
}) {
  return (
    <>
      <Head title="No supported methods" />
      <Step flow={flow} title="No supported methods">
        <Alert variant="warning">
          <AlertTitle>Nothing both sides can do</AlertTitle>
          <AlertDescription>
            The other session offered{" "}
            {flow.methods.length === 0 ? "no method at all" : flow.methods.join(", ")}, and this one
            does emoji and QR codes. There is no way to compare anything.
          </AlertDescription>
        </Alert>

        {offered.length > 0 && (
          <div className="flex flex-col gap-2 rounded-md border p-4 text-sm">
            <span className="text-muted-foreground">What both sides can do</span>
            {offered.map((method) => (
              <span key={method}>{NAMES[method] || method}</span>
            ))}
          </div>
        )}

        <div className="flex items-center gap-2">
          {flow.live && (
            <Act flow={flow} action="cancel" code="m.unknown_method">
              Cancel
            </Act>
          )}
          <Button size="sm" variant="ghost" render={<Link href="/matrix/verification" />}>
            Back
          </Button>
        </div>
      </Step>
    </>
  )
}
