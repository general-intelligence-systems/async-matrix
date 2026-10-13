# frozen_string_literal: true

# /matrix/verification/:flowId/confirm — Confirm QR code
#
# Fractal: identity_verification_view/confirm_qr_code_page.{blp,rs}
#
# NOT IMPLEMENTED.
#
# We scanned theirs, and confirming is what signs it.
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

get "/" do
  render(
    "matrix/verification/[flowId]/confirm",
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

export default function MatrixVerificationFlowidConfirm({flowId}: {
  flowId: string
}) {
  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title={"Confirm QR code"} />

      <ShellHeader>
        <Link href={"/matrix/verification"} className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">Confirm QR code</h1>
      </ShellHeader>

      <div className="mx-auto flex w-full max-w-xl flex-col gap-4 p-6">
        <Alert>
          <AlertTitle>Not implemented</AlertTitle>
          <AlertDescription>
            Scaffolded from Fractal's <code>identity_verification_view/confirm_qr_code_page.blp</code>. The widget tree to rebuild is in the
            route file.
          </AlertDescription>
        </Alert>
      </div>
    </div>
  )
}
