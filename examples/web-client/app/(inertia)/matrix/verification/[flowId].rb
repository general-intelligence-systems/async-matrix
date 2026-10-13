# frozen_string_literal: true

# /matrix/verification/:flowId — Verification
#
# Fractal: identity_verification_view/ (session/verification/identity_verification.rs)
#
# NOT IMPLEMENTED.
#
# One verification flow: SAS emoji or QR, through Fractal's thirteen
# VerificationStates.
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
# identity_verification_view/sas_emoji.blp
#
#   <Adw.Bin id="IdentityVerificationSasEmoji">
#     <Gtk.Box>
#       <Gtk.Label id="emoji" />
#       <Gtk.Label id="emoji_name" />
#     </Gtk.Box>
#   </Adw.Bin>
#
# identity_verification_view/scan_qr_code_page.blp
#
#   <Adw.Bin id="IdentityVerificationScanQrCodePage">
#     <Gtk.ScrolledWindow id="scrolled_window">
#       <Adw.Clamp slot="child">
#         <Gtk.Box slot="child">
#           <Gtk.Label id="title" />
#           <Gtk.Label id="instructions" />
#           <Adw.Bin id="qrcode_scanner_bin" />
#           <Gtk.Label id="cannot_scan_label" />
#           <Gtk.Button id="show_qr_code_btn" />
#           <LoadingButton id="start_sas_btn" />
#           <LoadingButton id="cancel_btn" />
#         </Gtk.Box>
#       </Adw.Clamp>
#     </Gtk.ScrolledWindow>
#   </Adw.Bin>
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
# ── Build with ─────────────────────────────────────────────────────────────
#
# @reui/onboarding-5 — "Multi-step workspace onboarding dialog with dot stepper,
#   animated steps, and success screen". Thirteen VerificationStates with a success and
#   a cancelled terminal is a stepper with branches; reui/stepper (vendored) is the
#   component, onboarding-5 is how to dress it.
#
#   VerificationState (13)             ->  reui/stepper — already vendored
#   AcceptRequestPage                  ->  ui/card + accept / decline
#   ChooseMethodPage                   ->  ui/radio-group — SAS / QR show / QR scan
#   SasPage + SasEmoji                 ->  a 7-emoji grid; ui/toggle-group for match / no-match
#   ScanQrCodePage                     ->  camera — browser getUserMedia, no catalog equivalent
#   ConfirmQrCodePage / QrCodeScanned  ->  ui/card + confirm
#   WaitForOtherPage                   ->  ui/spinner
#   CompletedPage                      ->  onboarding-5's success screen
#   CancelledPage / RoomLeftPage       ->  reui/alert, destructive
#   NoSupportedMethodsPage             ->  ui/empty
#
# NO CATALOG MATCH, hand-build:
#   The QR scanner. Fractal uses a GTK camera widget; the web equivalent is
#   getUserMedia plus a JS decoder, and nothing in the catalog covers it.
#
# One verification flow. Fractal has thirteen VerificationStates with two
# terminals; the view is a stepper whose current step is that state.
get "/" do
  render(
    "matrix/verification/[flowId]",
    flowId: params["flowId"].to_s,
    state:  "requested",
    other:  { userId: nil, displayName: nil, deviceId: nil },
    emoji:  [],
  )
end

post "/" do
  halt(501, "matrix: not implemented\n")
end

__END__

import { Head, Link } from "@inertiajs/react"
import { ArrowLeft, Check, QrCode, ShieldCheck, X } from "lucide-react"

import { Alert, AlertDescription, AlertTitle } from "@/components/reui/alert"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Label } from "@/components/ui/label"
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group"
import { Spinner } from "@/components/ui/spinner"
import { ShellHeader } from "@/components/admin/slots"

type Emoji = { symbol: string; name: string }

// Fractal's thirteen VerificationStates, collapsed to the five the view
// actually has to draw differently. The rest are waiting states.
const STEPS = [
  { key: "requested", label: "Request" },
  { key: "ready", label: "Method" },
  { key: "sas", label: "Compare" },
  { key: "done", label: "Done" },
]

export default function MatrixVerificationFlow({
  flowId,
  state,
  other,
  emoji,
}: {
  flowId: string
  state: string
  other: { userId: string | null; displayName: string | null; deviceId: string | null }
  emoji: Emoji[]
}) {
  const who = other.displayName ?? other.userId ?? "the other device"
  const index = Math.max(0, STEPS.findIndex((step) => step.key === state))
  const cancelled = state === "cancelled" || state === "error" || state === "room_left"

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title="Verification · matrix" />

      <ShellHeader>
        <Link href="/matrix/verification" className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="text-sm font-medium">Verify {who}</h1>
      </ShellHeader>

      <div className="mx-auto flex w-full max-w-xl flex-col gap-4 p-6">
        {/* The stepper, as a progress rail rather than a control -- the state
            is the server's, so a step is never something you click back to. */}
        <ol className="flex items-center gap-2">
          {STEPS.map((step, position) => (
            <li key={step.key} className="flex flex-1 items-center gap-2">
              <span
                className={
                  position <= index
                    ? "flex size-6 shrink-0 items-center justify-center rounded-full bg-primary text-xs text-primary-foreground"
                    : "flex size-6 shrink-0 items-center justify-center rounded-full border text-xs text-muted-foreground"
                }
              >
                {position < index ? <Check className="size-3" /> : position + 1}
              </span>
              <span className="truncate text-xs text-muted-foreground">{step.label}</span>
              {position < STEPS.length - 1 && <span className="h-px flex-1 bg-border" />}
            </li>
          ))}
        </ol>

        {cancelled ? (
          <Alert variant="destructive">
            <AlertTitle>Verification cancelled</AlertTitle>
            <AlertDescription>
              Either side can cancel, and a cancelled flow cannot be resumed. Start a new one.
            </AlertDescription>
          </Alert>
        ) : state === "done" ? (
          <Card>
            <CardContent className="flex flex-col items-center gap-3 py-10">
              <ShieldCheck className="size-10 text-primary" />
              <p className="text-sm font-medium">Verified</p>
              <p className="text-center text-sm text-muted-foreground">
                {who} is confirmed. Messages between you are now marked as trusted.
              </p>
              <Button size="sm" nativeButton={false} render={<Link href="/matrix/settings/devices" />}>Done</Button>
            </CardContent>
          </Card>
        ) : state === "sas" ? (
          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Compare the emoji</CardTitle>
              <CardDescription>
                {/* If they differ, somebody is in the middle -- which is the
                    whole point of the exercise, so the warning is not hedged. */}
                Both devices should show the same seven, in the same order. If they do not,
                stop: the connection is being intercepted.
              </CardDescription>
            </CardHeader>
            <CardContent className="flex flex-col gap-4">
              <div className="grid grid-cols-4 gap-3 sm:grid-cols-7">
                {emoji.length === 0
                  ? Array.from({ length: 7 }).map((_, position) => (
                      <div
                        key={position}
                        className="flex aspect-square items-center justify-center rounded-md border bg-muted/40"
                      />
                    ))
                  : emoji.map((item) => (
                      <div
                        key={item.name}
                        className="flex aspect-square flex-col items-center justify-center gap-1 rounded-md border"
                      >
                        <span className="text-2xl">{item.symbol}</span>
                        <span className="text-[10px] text-muted-foreground">{item.name}</span>
                      </div>
                    ))}
              </div>
              <div className="flex gap-2">
                <Button size="sm">
                  <Check className="size-4" />
                  They match
                </Button>
                <Button size="sm" variant="destructive">
                  <X className="size-4" />
                  They do not
                </Button>
              </div>
            </CardContent>
          </Card>
        ) : state === "ready" ? (
          <Card>
            <CardHeader>
              <CardTitle className="text-sm">How to verify</CardTitle>
            </CardHeader>
            <CardContent className="flex flex-col gap-4">
              <RadioGroup defaultValue="sas" className="gap-3">
                <div className="flex items-start gap-3">
                  <RadioGroupItem value="sas" id="m-sas" className="mt-0.5" />
                  <div className="flex flex-col gap-0.5">
                    <Label htmlFor="m-sas" className="font-normal">Compare emoji</Label>
                    <span className="text-xs text-muted-foreground">
                      Works when you can see both screens.
                    </span>
                  </div>
                </div>
                <div className="flex items-start gap-3">
                  <RadioGroupItem value="qr" id="m-qr" className="mt-0.5" />
                  <div className="flex flex-col gap-0.5">
                    <Label htmlFor="m-qr" className="font-normal">
                      <QrCode className="mr-1 inline size-3.5" />
                      Scan a QR code
                    </Label>
                    <span className="text-xs text-muted-foreground">
                      Needs a camera on one of the two devices.
                    </span>
                  </div>
                </div>
              </RadioGroup>
              <Button size="sm" className="self-start">
                Continue
              </Button>
            </CardContent>
          </Card>
        ) : (
          <Card>
            <CardContent className="flex flex-col items-center gap-3 py-10">
              <Spinner />
              <p className="text-sm font-medium">Waiting for {who}</p>
              <p className="text-center text-sm text-muted-foreground">
                They have to accept the request on their end before this can continue.
              </p>
              <Button size="sm" variant="outline">
                Cancel request
              </Button>
            </CardContent>
          </Card>
        )}

        <code className="text-center font-mono text-[10px] text-muted-foreground">{flowId}</code>
      </div>
    </div>
  )
}
