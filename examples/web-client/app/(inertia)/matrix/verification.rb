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
  render("matrix/verification", requests: [])
end

__END__

import { Head, Link } from "@inertiajs/react"
import { ShieldCheck } from "lucide-react"

import { Avatar, AvatarFallback } from "@/components/ui/avatar"
import { Button } from "@/components/ui/button"
import { Empty, EmptyDescription, EmptyHeader, EmptyMedia, EmptyTitle } from "@/components/ui/empty"
import { Item, ItemContent, ItemDescription, ItemMedia, ItemTitle } from "@/components/ui/item"
import { Progress } from "@/components/ui/progress"
import { ScrollArea } from "@/components/ui/scroll-area"
import { ShellHeader } from "@/components/admin/slots"

type Request = {
  flowId: string
  userId: string
  displayName: string | null
  state: string
  receivedAt: number
  expiresIn: number
}

export default function MatrixVerification({ requests }: { requests: Request[] }) {
  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title="Verification · matrix" />

      <ShellHeader>
        <h1 className="text-sm font-medium">Verification</h1>
      </ShellHeader>

      <ScrollArea className="min-h-0 flex-1">
        <div className="mx-auto w-full max-w-2xl p-6">
          {requests.length === 0 ? (
            <Empty className="py-12">
              <EmptyHeader>
                <EmptyMedia variant="icon">
                  <ShieldCheck />
                </EmptyMedia>
                <EmptyTitle>No pending requests</EmptyTitle>
                <EmptyDescription>
                  Start one from a device or a profile. Requests expire, so they only appear
                  here while they are live.
                </EmptyDescription>
              </EmptyHeader>
            </Empty>
          ) : (
            <div className="flex flex-col gap-1">
              {requests.map((request) => (
                <Item key={request.flowId}>
                  <ItemMedia>
                    <Avatar className="size-8">
                      <AvatarFallback className="text-[11px]">
                        {(request.displayName ?? request.userId).replace(/^@/, "").charAt(0).toUpperCase()}
                      </AvatarFallback>
                    </Avatar>
                  </ItemMedia>
                  <ItemContent>
                    <ItemTitle>{request.displayName ?? request.userId}</ItemTitle>
                    <ItemDescription>{request.state}</ItemDescription>
                    <Progress value={request.expiresIn} className="mt-1 h-1" />
                  </ItemContent>
                  <Button size="sm" nativeButton={false} render={<Link href={`/matrix/verification/${encodeURIComponent(request.flowId)}`} />}>
                      Continue
                    </Button>
                </Item>
              ))}
            </div>
          )}
        </div>
      </ScrollArea>
    </div>
  )
}
