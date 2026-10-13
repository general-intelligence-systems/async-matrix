# frozen_string_literal: true

# /matrix/verification — Verification
#
# Fractal: session_view/content.blp stack page "verification" + verification_list.rs
#
# Pending identity verification requests. A content-pane state in Fractal
# because it is a single-window app; a route here so a request is linkable.
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
# identity_verification_view/mod.blp
#
#   <Adw.Bin id="IdentityVerificationView">
#     <Gtk.Stack id="main_stack">
#       <Gtk.StackPage>
#         <IdentityVerificationAcceptRequestPage slot="child" id="accept_request_page" />
#       </Gtk.StackPage>
#       <Gtk.StackPage>
#         <IdentityVerificationWaitForOtherPage slot="child" id="wait_for_other_page" />
#       </Gtk.StackPage>
#       <Gtk.StackPage>
#         <IdentityVerificationNoSupportedMethodsPage slot="child" id="no_supported_methods_page" />
#       </Gtk.StackPage>
#       <Gtk.StackPage>
#         <IdentityVerificationChooseMethodPage slot="child" id="choose_method_page" />
#       </Gtk.StackPage>
#       <Gtk.StackPage>
#         <IdentityVerificationQrCodeScannedPage slot="child" id="qr_code_scanned_page" />
#       </Gtk.StackPage>
#       <Gtk.StackPage>
#         <IdentityVerificationConfirmQrCodePage slot="child" id="confirm_qr_code_page" />
#       </Gtk.StackPage>
#       <Gtk.StackPage>
#         <IdentityVerificationSasPage slot="child" id="sas_page" />
#       </Gtk.StackPage>
#       <Gtk.StackPage>
#         <IdentityVerificationCompletedPage slot="child" id="completed_page" />
#       </Gtk.StackPage>
#       <Gtk.StackPage>
#         <IdentityVerificationCancelledPage slot="child" id="cancelled_page" />
#       </Gtk.StackPage>
#       <Gtk.StackPage>
#         <IdentityVerificationRoomLeftPage slot="child" id="room_left_page" />
#       </Gtk.StackPage>
#     </Gtk.Stack>
#   </Adw.Bin>
#
# session_view/sidebar/verification_row.blp
#
#   <Adw.Bin id="SidebarVerificationRow">
#     <Gtk.Box>
#       <Gtk.Image />
#       <Gtk.Label id="display_name" />
#       <Gtk.Label />
#     </Gtk.Box>
#   </Adw.Bin>
#
# ── Build with ─────────────────────────────────────────────────────────────
#
# @reui/empty-state-7 plus ui/item rows. A pending-request list is short, usually empty,
#   and time-sensitive -- so the empty state is most of the screen most of the time.
#
#   VerificationList         ->  ui/item rows
#   SidebarVerificationRow   ->  ui/item + ui/avatar + ui/badge
#   received_time / timeout  ->  ui/progress — requests expire
#   no requests              ->  ui/empty
#
# Pending verification requests. Short, usually empty, and time-sensitive --
# a request expires, so the empty state is most of this screen most of the time.
get "/" do
  render(
    "matrix/verification",
    requests: Models::Matrix::VerificationFlow.newest_first.limit(50).map{|flow| verification_row(flow)},
  )
end

post "/" do
  user_id = params["user_id"].to_s

  if user_id.empty?
    halt(400, "matrix: no user\n")
  end

  flow = Matrix::Verification.request!(user_id)

  redirect("/matrix/verification/#{CGI.escape(flow.flow_id)}/wait", 303)
rescue Matrix::RoomActions::Error => error
  halt(409, "matrix: #{error.message}\n")
end

__END__

import { Form, Head, Link } from "@inertiajs/react"
import { ShieldCheck, ShieldQuestion, ShieldX } from "lucide-react"

import { Alert, AlertDescription, AlertTitle } from "@/components/reui/alert"
import { Badge } from "@/components/reui/badge"
import { Button } from "@/components/ui/button"
import { Item, ItemContent, ItemDescription, ItemTitle } from "@/components/ui/item"
import { ScrollArea } from "@/components/ui/scroll-area"
import { ShellHeader } from "@/components/admin/slots"

type Request = {
  flowId: string
  userId: string
  displayName: string | null
  deviceId: string | null
  state: string
  live: boolean
  startedByUs: boolean
  cancelReason: string | null
}

const LABELS: Record<string, string> = {
  requested: "Requested",
  ready: "Ready",
  started: "Started",
  accepted: "Accepted",
  keyed: "Compare emoji",
  confirmed: "Waiting for them",
  done: "Verified",
  cancelled: "Cancelled",
}

export default function MatrixVerification({ requests }: { requests: Request[] }) {
  const live = requests.filter((request) => request.live)
  const past = requests.filter((request) => !request.live)

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title="Verification · matrix" />

      <ShellHeader>
        <h1 className="text-sm font-medium">Verification</h1>
      </ShellHeader>

      <ScrollArea className="min-h-0 flex-1">
        <div className="mx-auto flex w-full max-w-2xl flex-col gap-4 p-6">
          {live.length === 0 && (
            <Alert>
              <AlertTitle>Nothing is waiting</AlertTitle>
              <AlertDescription>
                A request appears here when another session or another person asks to verify, and
                when you start one from{" "}
                <Link href="/matrix/settings/encryption/identity" className="underline">
                  your crypto identity
                </Link>
                .
              </AlertDescription>
            </Alert>
          )}

          {live.map((request) => (
            <Item key={request.flowId} variant="outline">
              <ItemContent>
                <ItemTitle className="flex items-center gap-2">
                  <ShieldQuestion className="size-4" />
                  {request.displayName || request.userId}
                  <Badge variant="secondary" size="sm">
                    {LABELS[request.state] || request.state}
                  </Badge>
                </ItemTitle>
                <ItemDescription className="font-mono text-xs">
                  {request.deviceId || "every session"}
                </ItemDescription>
              </ItemContent>
              <Button
                size="sm"
                render={<Link href={`/matrix/verification/${encodeURIComponent(request.flowId)}`} />}
              >
                {request.startedByUs ? "Continue" : "Answer"}
              </Button>
            </Item>
          ))}

          {past.length > 0 && (
            <>
              <h2 className="mt-2 text-xs font-medium tracking-wide text-muted-foreground uppercase">
                Finished
              </h2>
              {past.map((request) => (
                <Item key={request.flowId} variant="muted">
                  <ItemContent>
                    <ItemTitle className="flex items-center gap-2">
                      {request.state === "done" ? (
                        <ShieldCheck className="size-4 text-primary" />
                      ) : (
                        <ShieldX className="size-4 text-muted-foreground" />
                      )}
                      {request.displayName || request.userId}
                    </ItemTitle>
                    <ItemDescription>
                      {request.state === "done"
                        ? "Verified"
                        : request.cancelReason || "Cancelled"}
                    </ItemDescription>
                  </ItemContent>
                  <Button
                    size="sm"
                    variant="ghost"
                    render={<Link href={`/matrix/verification/${encodeURIComponent(request.flowId)}`} />}
                  >
                    Open
                  </Button>
                </Item>
              ))}
            </>
          )}

          <Form action="/matrix/verification" method="post" className="mt-2 flex items-end gap-2">
            {({ processing }) => (
              <>
                <input
                  type="text"
                  name="user_id"
                  placeholder="@someone:example.org"
                  className="h-9 flex-1 rounded-md border bg-transparent px-3 text-sm"
                />
                <Button type="submit" size="sm" variant="outline" disabled={processing}>
                  Ask to verify
                </Button>
              </>
            )}
          </Form>
        </div>
      </ScrollArea>
    </div>
  )
}
