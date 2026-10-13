# frozen_string_literal: true

# /matrix/verification/:flowId/completed — Verified
#
# Fractal: identity_verification_view/completed_page.{blp,rs}
#
# The flow finished and the signature is published.
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
# identity_verification_view/completed_page.blp
#
#   <Adw.Bin id="IdentityVerificationCompletedPage">
#     <Gtk.ScrolledWindow id="scrolled_window">
#       <Adw.Clamp slot="child">
#         <Gtk.Box slot="child">
#           <Gtk.Label id="title" />
#           <Gtk.Picture />
#           <Gtk.Label id="message" />
#           <Gtk.Button id="dismiss_btn" />
#         </Gtk.Box>
#       </Adw.Clamp>
#     </Gtk.ScrolledWindow>
#   </Adw.Bin>
#

get "/" do
  flow = verification_flow!

  render(
    "matrix/verification/[flowId]/completed",
    flow: verification_row(flow),
    step: verification_step(flow),
  )
end

__END__

import { Head, Link } from "@inertiajs/react"
import { ShieldCheck } from "lucide-react"

import { Alert, AlertDescription, AlertTitle } from "@/components/reui/alert"
import { Button } from "@/components/ui/button"
import { Flow, Stale, Step } from "@/components/matrix/verification"

export default function MatrixVerificationCompleted({ flow, step }: { flow: Flow; step: string }) {
  return (
    <>
      <Head title="Verified" />
      <Step flow={flow} title="Verified">
        {step === "completed" ? null : <Stale flow={flow} />}

        <div className="flex flex-col items-center gap-2 py-4">
          <ShieldCheck className="size-10 text-primary" />
          <h2 className="text-center text-xl font-semibold tracking-tight">
            {flow.own ? "Session Verified" : "Verification Complete"}
          </h2>
        </div>

        <Alert>
          <AlertTitle>The signature is published</AlertTitle>
          <AlertDescription>
            {flow.own
              ? "This session can read your encrypted messages, and your other sessions trust it."
              : "Your clients trust each other's keys. A new device of theirs will need verifying again."}
          </AlertDescription>
        </Alert>

        <div className="flex items-center gap-2">
          <Button size="sm" render={<Link href="/matrix/settings/encryption" />}>
            Encryption settings
          </Button>
          <Button size="sm" variant="outline" render={<Link href="/matrix/verification" />}>
            Done
          </Button>
        </div>
      </Step>
    </>
  )
}
