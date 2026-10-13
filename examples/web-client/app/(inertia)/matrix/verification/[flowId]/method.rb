# frozen_string_literal: true

# /matrix/verification/:flowId/method — Choose a method
#
# Fractal: identity_verification_view/choose_method_page.{blp,rs}
#
# NOT IMPLEMENTED.
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
  render(
    "matrix/verification/[flowId]/method",
    flowId:    params["flowId"],
  )
end

post "/" do
  halt(501, "matrix: not implemented\n")
end

__END__

import { Head, Link } from "@inertiajs/react"
import { ArrowLeft } from "lucide-react"

import { Alert, AlertDescription, AlertTitle } from "@/components/reui/alert"
import { ShellHeader } from "@/components/admin/slots"

export default function MatrixVerificationFlowidMethod({flowId}: {
  flowId: string
}) {
  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title={"Choose a method"} />

      <ShellHeader>
        <Link href={"/matrix/verification"} className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">Choose a method</h1>
      </ShellHeader>

      <div className="mx-auto flex w-full max-w-xl flex-col gap-4 p-6">
        <Alert>
          <AlertTitle>Not implemented</AlertTitle>
          <AlertDescription>
            Scaffolded from Fractal's <code>identity_verification_view/choose_method_page.blp</code>. The widget tree to rebuild is in the
            route file.
          </AlertDescription>
        </Alert>
      </div>
    </div>
  )
}
