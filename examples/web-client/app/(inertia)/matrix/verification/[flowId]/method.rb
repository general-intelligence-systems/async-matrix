# frozen_string_literal: true

# /matrix/verification/:flowId/method — Choose a method
#
# Fractal: identity_verification_view/choose_method_page.{blp,rs}
#
# QR code or emoji, which is m.qr_code.show.v1 against m.sas.v1.
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
# identity_verification_view/choose_method_page.blp
#
#   <Adw.Bin id="IdentityVerificationChooseMethodPage">
#     <Gtk.ScrolledWindow id="scrolled_window">
#       <Adw.Clamp slot="child">
#         <Gtk.Box slot="child">
#           <Gtk.Label id="title" />
#           <Gtk.Label id="instructions" />
#           <TriQRCode id="qrcode" />
#           <Gtk.Label id="cannot_scan_label" />
#           <LoadingButton id="scan_qr_code_btn" />
#           <LoadingButton id="start_sas_btn" />
#           <LoadingButton id="cancel_btn" />
#         </Gtk.Box>
#       </Adw.Clamp>
#     </Gtk.ScrolledWindow>
#   </Adw.Bin>
#

get "/" do
  flow = verification_flow!

  render(
    "matrix/verification/[flowId]/method",
    flow:    verification_row(flow),
    step:    verification_step(flow),
    offered: Matrix::Verification.offered(flow),
    qr:      Matrix::Verification.qr_payload(flow),
  )
end

__END__

import { Head, Link } from "@inertiajs/react"
import { QrCode, SmilePlus } from "lucide-react"

import { Alert, AlertDescription, AlertTitle } from "@/components/reui/alert"
import { Button } from "@/components/ui/button"
import { Item, ItemContent, ItemDescription, ItemTitle } from "@/components/ui/item"
import { usePoll } from "@/hooks/use-poll"
import { Act, Flow, Stale, Step, flowPath } from "@/components/matrix/verification"

export default function MatrixVerificationMethod({
  flow,
  step,
  offered,
  qr,
}: {
  flow: Flow
  step: string
  offered: string[]
  qr: string | null
}) {
  usePoll(flow.live, ["flow", "step"])

  const sas = offered.includes("m.sas.v1")
  const scan = offered.includes("m.qr_code.show.v1") && qr !== null

  return (
    <>
      <Head title="Choose a method" />
      <Step flow={flow} title="Choose a method">
        {step === "method" ? null : <Stale flow={flow} />}

        {!sas && !scan && (
          <Alert variant="warning">
            <AlertTitle>Nothing both sides can do</AlertTitle>
            <AlertDescription>
              <Link href={flowPath(flow, "unsupported")} className="underline">
                See what that means
              </Link>
            </AlertDescription>
          </Alert>
        )}

        {sas && (
          <Item variant="outline">
            <ItemContent>
              <ItemTitle className="flex items-center gap-2">
                <SmilePlus className="size-4" />
                Compare emoji
              </ItemTitle>
              <ItemDescription>
                Seven emoji appear on both screens. They match or they do not.
              </ItemDescription>
            </ItemContent>
            <Act flow={flow} action="start">
              Start
            </Act>
          </Item>
        )}

        {scan && (
          <Item variant="outline">
            <ItemContent>
              <ItemTitle className="flex items-center gap-2">
                <QrCode className="size-4" />
                Show a QR code
              </ItemTitle>
              <ItemDescription>Let the other device scan this one's code.</ItemDescription>
            </ItemContent>
            <Button size="sm" variant="outline" render={<Link href={flowPath(flow, "scan")} />}>
              Show
            </Button>
          </Item>
        )}

        <Act flow={flow} action="cancel" code="user" variant="ghost">
          Cancel
        </Act>
      </Step>
    </>
  )
}
