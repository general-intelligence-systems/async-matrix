# frozen_string_literal: true

# /matrix/verification/:flowId — Verification
#
# Fractal: identity_verification_view/ (session/verification/identity_verification.rs)
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
# The flow's own page is the step it is on, so a link to it never goes stale.
get "/" do
  flow = verification_flow!

  redirect("/matrix/verification/#{CGI.escape(flow.flow_id)}/#{verification_step(flow)}", 303)
end

post "/" do
  flow = verification_flow!

  case params["action"].to_s
  in "accept"
    Matrix::Verification.accept_request!(flow.flow_id)
  in "start"
    Matrix::Verification.start!(flow.flow_id)
  in "confirm"
    Matrix::Verification.confirm!(flow.flow_id)
  in "confirm_qr"
    Matrix::Verification.confirm_qr!(flow.flow_id)
  in "scanned"
    Matrix::Verification.scanned!(flow.flow_id, params["payload"].to_s)
  in "cancel"
    Matrix::Verification.cancel!(
      flow.flow_id, code: params.fetch("code", "user").to_s, reason: params["reason"],
    )
  else
    halt(400, "matrix: no such action\n")
  end

  back = params["return_to"].to_s

  if back.empty?
    redirect("/matrix/verification/#{CGI.escape(flow.flow_id)}", 303)
  else
    redirect(back, 303)
  end
rescue Matrix::RoomActions::Error => error
  halt(409, "matrix: #{error.message}\n")
rescue Async::Matrix::RequestError => error
  halt(error.status, "matrix: #{error.message}\n")
end

__END__

import { Head } from "@inertiajs/react"

import { ShellHeader } from "@/components/admin/slots"

// Never rendered: the route redirects to whichever step the flow is on.
export default function MatrixVerificationFlow() {
  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title="Verification" />

      <ShellHeader>
        <h1 className="text-sm font-medium">Verification</h1>
      </ShellHeader>
    </div>
  )
}
