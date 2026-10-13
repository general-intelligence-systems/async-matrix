# frozen_string_literal: true

# /matrix/verification/:flowId/scan — Scan QR code
#
# Fractal: identity_verification_view/scan_qr_code_page.{blp,rs}
#
# Scanning the other session's QR code with a camera.
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

get "/" do
  flow = verification_flow!

  render(
    "matrix/verification/[flowId]/scan",
    flow: verification_row(flow),
    step: verification_step(flow),
    qr:   Matrix::Verification.qr_payload(flow),
  )
end

__END__

import { Head, Link } from "@inertiajs/react"
import QRCode from "qrcode"
import { useEffect, useRef, useState } from "react"

import { Alert, AlertDescription, AlertTitle } from "@/components/reui/alert"
import { Button } from "@/components/ui/button"
import { usePoll } from "@/hooks/use-poll"
import { Act, Flow, Stale, Step, flowPath } from "@/components/matrix/verification"

export default function MatrixVerificationScan({
  flow,
  step,
  qr,
}: {
  flow: Flow
  step: string
  qr: string | null
}) {
  const canvas = useRef<HTMLCanvasElement>(null)
  const video = useRef<HTMLVideoElement>(null)
  const [camera, setCamera] = useState<string | null>(null)
  const [scanning, setScanning] = useState(false)
  const [payload, setPayload] = useState("")

  usePoll(flow.live, ["flow", "step"])

  // The code carries raw bytes, so it goes in as Latin-1 rather than as text.
  useEffect(() => {
    if (qr && canvas.current) {
      void QRCode.toCanvas(canvas.current, [{ data: atob(qr.replace(/-/g, "+").replace(/_/g, "/")), mode: "byte" }], {
        width: 240,
        margin: 2,
      })
    }
  }, [qr])

  useEffect(() => {
    if (!scanning) {
      return
    }

    const Detector = (window as unknown as { BarcodeDetector?: new (options: { formats: string[] }) => { detect: (source: CanvasImageSource) => Promise<{ rawValue: string }[]> } }).BarcodeDetector

    if (!Detector) {
      setCamera("This browser cannot read a QR code. Compare the emoji instead.")
      setScanning(false)

      return
    }

    let stream: MediaStream | null = null
    let timer = 0
    const detector = new Detector({ formats: ["qr_code"] })

    navigator.mediaDevices
      .getUserMedia({ video: { facingMode: "environment" } })
      .then((opened) => {
        stream = opened

        if (video.current) {
          video.current.srcObject = opened
          void video.current.play()
        }

        timer = window.setInterval(() => {
          if (video.current && video.current.readyState === 4) {
            void detector.detect(video.current).then((codes) => {
              if (codes.length > 0) {
                setPayload(btoa(codes[0].rawValue).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, ""))
                setScanning(false)
              }
            })
          }
        }, 400)
      })
      .catch((error: Error) => {
        setCamera(error.message)
        setScanning(false)
      })

    return () => {
      window.clearInterval(timer)
      stream?.getTracks().forEach((track) => track.stop())
    }
  }, [scanning])

  return (
    <>
      <Head title="Scan QR code" />
      <Step flow={flow} title="Scan QR code" back={flowPath(flow, "method")}>
        {step === "method" || step === "wait" ? null : <Stale flow={flow} />}

        {qr ? (
          <>
            <Alert>
              <AlertTitle>Let the other device scan this</AlertTitle>
              <AlertDescription>
                It confirms on its own screen, and this one asks you to confirm in turn.
              </AlertDescription>
            </Alert>
            <canvas ref={canvas} className="self-center rounded-md bg-white p-2" />
          </>
        ) : (
          <Alert variant="warning">
            <AlertTitle>No code to show</AlertTitle>
            <AlertDescription>
              A QR code needs both sides' keys, and one of them is not known yet.{" "}
              <Link href={flowPath(flow, "method")} className="underline">
                Compare emoji instead
              </Link>
            </AlertDescription>
          </Alert>
        )}

        <hr className="border-dashed" />

        <h2 className="text-sm font-medium">Or scan theirs</h2>

        {camera ? (
          <Alert variant="warning">
            <AlertTitle>The camera is not available</AlertTitle>
            <AlertDescription>{camera}</AlertDescription>
          </Alert>
        ) : null}

        {scanning ? (
          <video ref={video} className="w-full rounded-md border" muted playsInline />
        ) : (
          <Button size="sm" variant="outline" onClick={() => setScanning(true)} className="self-start">
            Use the camera
          </Button>
        )}

        {payload ? (
          <Act flow={flow} action="scanned" fields={{ payload }} returnTo={flowPath(flow, "confirm")}>
            Confirm the code that was read
          </Act>
        ) : null}

        <Act flow={flow} action="cancel" code="user" variant="ghost">
          Cancel
        </Act>
      </Step>
    </>
  )
}
