# frozen_string_literal: true

# /matrix — Matrix
#
# Fractal: session_view/content.blp stack page "empty"
#
# NOT IMPLEMENTED.
#
# The empty state: no room selected. See the open question in the plan about
# redirecting to the most recently active room instead.
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
# session_view/content.blp
#
#   <Adw.NavigationPage id="Content">
#     <Gtk.Stack slot="child" id="stack">
#       <Gtk.StackPage>
#         <Adw.ToolbarView slot="child" id="empty_page">
#           <Adw.HeaderBar id="empty_page_header_bar" />
#           <Adw.StatusPage slot="content" />
#         </Adw.ToolbarView>
#       </Gtk.StackPage>
#       <Gtk.StackPage>
#         <ContentRoomHistory slot="child" id="room_history" />
#       </Gtk.StackPage>
#       <Gtk.StackPage>
#         <ContentInviteRequest slot="child" id="invite_request" />
#       </Gtk.StackPage>
#       <Gtk.StackPage>
#         <ContentInvite slot="child" id="invite" />
#       </Gtk.StackPage>
#       <Gtk.StackPage>
#         <ContentExplore slot="child" id="explore" />
#       </Gtk.StackPage>
#       <Gtk.StackPage>
#         <Adw.ToolbarView slot="child" id="verification_page">
#           <Adw.HeaderBar id="verification_page_header_bar" />
#           <IdentityVerificationView slot="content" id="identity_verification_widget" />
#         </Adw.ToolbarView>
#       </Gtk.StackPage>
#     </Gtk.Stack>
#   </Adw.NavigationPage>
#
# ── Build with ─────────────────────────────────────────────────────────────
#
# @reui/empty-state-11 — "Section-header empty state with action button above a muted
#   card and stacked icon illustration". Fractal's is an Adw.StatusPage; Empty is the
#   primitive and the block is the dressed version.
#
#   Adw.StatusPage  ->  ui/empty (title / description / actions slots)
#   illustration    ->  reui/icon-stack — already vendored
#
# The empty state. Fractal shows this when no room is selected; there is no
# redirect to the last room because /matrix has to stay a stable URL.
get "/" do
  render("matrix/index", roomCount: Models::Matrix::Room.count)
end

__END__

import { Head, Link } from "@inertiajs/react"
import { MessagesSquare, Search } from "lucide-react"

import { Button } from "@/components/ui/button"
import {
  Empty,
  EmptyContent,
  EmptyDescription,
  EmptyHeader,
  EmptyMedia,
  EmptyTitle,
} from "@/components/ui/empty"
import { ShellHeader } from "@/components/admin/slots"

export default function MatrixIndex({ roomCount }: { roomCount: number }) {
  return (
    <>
      <Head title="Matrix" />

      <ShellHeader>
        <MessagesSquare className="size-4 shrink-0 text-muted-foreground" />
        <h1 className="truncate text-sm font-medium">Matrix</h1>
      </ShellHeader>

      <Empty className="flex-1">
        <EmptyHeader>
          <EmptyMedia variant="icon">
            <MessagesSquare />
          </EmptyMedia>
          <EmptyTitle>{roomCount > 0 ? "No room selected" : "No rooms yet"}</EmptyTitle>
          <EmptyDescription>
            {roomCount > 0
              ? "Pick a room from the sidebar to read it."
              : "Join or create a room, or wait for the device to finish its first sync."}
          </EmptyDescription>
        </EmptyHeader>
        <EmptyContent>
          <div className="flex gap-2">
            <Button nativeButton={false} render={<Link href="/matrix/rooms/new" />}>New room</Button>
            <Button variant="outline" nativeButton={false} render={<Link href="/matrix/explore" />}>
<Search className="size-4" />
                Explore
              </Button>
          </div>
        </EmptyContent>
      </Empty>
    </>
  )
}
