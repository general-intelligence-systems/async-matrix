# frozen_string_literal: true

# Everything under /matrix. Evaluated into every route file below it, which is
# why the device and the sidebar live here rather than being fetched per page.
#
# ONE DEVICE, NOT A SESSION LIST. matrix_credentials is unique on user_id and
# this app is a single operator behind SyncAuth, so Fractal's login/,
# account_switcher/ and session_list/ have no analogue -- the device is
# configured, not chosen. That is four of its fourteen top-level views gone.
#
# `share` is where the sidebar belongs: Fractal's SidebarItemList is one room
# list partitioned into SidebarSectionNames, and the partition is computable --
# matrix_rooms.favourite / .low_priority (m.tag), membership for invited and
# left, and `space`. See session/sidebar_data/section/name.rs for the sections.
#
# `share`, not `share_props`: share_props would register the block for every
# request in the app, including the pages that have nothing to do with Matrix.
#
# THE LIST GOES IN THE SHELL'S SIDEBAR AND EACH PAGE'S HEADER IN THE SHELL'S
# HEADER. The template below renders the room list into <ShellSidebar> and
# every page under here renders its bar into <ShellHeader>
# (frontend/components/admin/slots.tsx) rather than drawing either itself --
# this layout used to build its own <aside> and its own header bar, which came
# out as a second sidebar and a second header INSIDE the shell's.
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
# session_view/mod.blp
#
#   <Adw.Bin id="SessionView">
#     <Gtk.Stack slot="child" id="stack">
#       <Gtk.Overlay id="overlay">
#         <MediaViewer id="media_viewer" />
#         <Adw.NavigationSplitView id="split_view">
#           <Sidebar slot="sidebar" id="sidebar" />
#           <Content slot="content" id="content" />
#         </Adw.NavigationSplitView>
#       </Gtk.Overlay>
#     </Gtk.Stack>
#     <Gtk.ShortcutController>
#       <Gtk.Shortcut />
#       <Gtk.Shortcut />
#       <Gtk.Shortcut />
#       <Gtk.Shortcut />
#     </Gtk.ShortcutController>
#   </Adw.Bin>
#
# session_view/sidebar/mod.blp
#
#   <Adw.NavigationPage id="Sidebar">
#     <Adw.ToolbarView>
#       <Adw.HeaderBar id="header_bar">
#         <AccountSwitcherButton id="account_switcher_button" />
#         <Gtk.MenuButton id="appmenu_button" />
#         <Gtk.ToggleButton id="search_button" />
#       </Adw.HeaderBar>
#       <Gtk.SearchBar id="room_search">
#         <Gtk.SearchEntry slot="child" id="room_search_entry" />
#       </Gtk.SearchBar>
#       <Gtk.Box slot="content">
#         <OfflineBanner />
#         <Adw.Banner id="security_banner" />
#         <Stack id="room_stack">
#           <StackPage>
#             <Adw.StatusPage slot="child" />
#           </StackPage>
#           <StackPage>
#             <Gtk.ScrolledWindow slot="child" id="scrolled_window">
#               <Gtk.ListView slot="child" id="listview" />
#             </Gtk.ScrolledWindow>
#           </StackPage>
#         </Stack>
#       </Gtk.Box>
#     </Adw.ToolbarView>
#   </Adw.NavigationPage>
#
# session_view/sidebar/section_row.blp
#
#   <Adw.Bin id="SidebarSectionRow">
#     <Gtk.Box>
#       <Gtk.Label id="display_name" />
#       <Gtk.Stack>
#         <Gtk.StackPage>
#           <Gtk.Image slot="child" />
#         </Gtk.StackPage>
#         <Gtk.StackPage>
#           <Gtk.Label slot="child" id="notification_count" />
#         </Gtk.StackPage>
#       </Gtk.Stack>
#       <Gtk.Image id="arrow" />
#     </Gtk.Box>
#   </Adw.Bin>
#
# session_view/sidebar/room_row.blp
#
#   <Adw.Bin id="SidebarRoomRow">
#     <Gtk.Box>
#       <Avatar id="avatar" />
#       <Gtk.Box id="display_name_box">
#         <Gtk.Image id="room_icon" />
#         <Gtk.Label id="display_name" />
#       </Gtk.Box>
#       <Gtk.Stack>
#         <Gtk.StackPage>
#           <Gtk.Image slot="child" />
#         </Gtk.StackPage>
#         <Gtk.StackPage>
#           <Gtk.Label slot="child" id="notification_count" />
#         </Gtk.StackPage>
#       </Gtk.Stack>
#     </Gtk.Box>
#   </Adw.Bin>
#
# session_view/sidebar/icon_item_row.blp
#
#   <Adw.Bin id="SidebarIconItemRow">
#     <Gtk.Box>
#       <Gtk.Image />
#       <Gtk.Label />
#     </Gtk.Box>
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
# @reui/app-shell-21 — "AI chat workspace: resizable thread sidebar collapsing to an
#   icon rail, pinned and grouped chats, a search palette". VERIFIED IN THE BROWSER:
#   its sidebar is already Fractal's. "Pinned 2 / Recent 6" as collapsible groups with
#   counts IS SidebarSection -- name, is_expanded, notification_count -- and the
#   resizable pane IS Adw.NavigationSplitView. Built from Avatar, Badge, Collapsible,
#   Dialog, Dropdown Menu, Empty, Input Group, Item, Kbd, Resizable, Scroll Area, Sheet.
#
#   Adw.NavigationSplitView            ->  ui/resizable — a draggable split, which GTK gives free
#                                           and the web does not
#   Adw.NavigationPage (sidebar)       ->  ui/sidebar + ui/scroll-area
#   SidebarSection (7 of them)         ->  ui/collapsible per section; is_expanded is its open state
#   SidebarSection.notification_count  ->  ui/badge on the group header
#   SidebarRoomRow                     ->  ui/item — avatar + name + preview + count, which is
#                                           Item's shape
#   SidebarIconItem (Explore/Forget)   ->  ui/sidebar menu buttons
#   SidebarVerificationRow             ->  ui/item with a Badge
#   Gtk.StringFilter (sidebar search)  ->  ui/command — Cmd-K over rooms beats a filter box
#   Adw.Avatar                         ->  ui/avatar
#
# INSTALL, plain shadcn: command, collapsible
#

# Fractal's SidebarSectionName, in its order, with the dataset that selects each
# one. Its first two -- verification-request and invite-request -- have no table
# to come from and no section until there is, so five of the seven are here.
#
# `normal` is the default section: joined, and neither tagged. The partition is
# total, so a room appears in exactly one.
# Fractal's window is a four-state stack -- Loading, Login, Session, Error (window.rs WindowPage) -- and
# which one shows is decided by whether a usable session exists, not by where you navigated.
#
# This is that decision. Everything under /matrix needs a device whose tokens still work, so without
# one the only reachable screen is the login flow itself. A layout's `before` is class-level Sinatra
# DSL and reaches only the files below it, which is why it sits here and not in the root layout.
PUBLIC = %r{\A/matrix/(login|callback|error)(/|\z)}

before do
  unless PUBLIC.match?(request.path_info) || Models::Matrix::Credential.first&.usable?
    redirect("/matrix/login", 303)
  end
end

SECTIONS = [
  ["invited",      "Invites",      ->(rooms){rooms.where(membership: "invite")}],
  ["favorite",     "Favourites",   ->(rooms){rooms.joined.where(favourite: true)}],
  ["normal",       "Rooms",        ->(rooms){
    rooms.joined.where(favourite: false, low_priority: false)
  }],
  ["low-priority", "Low priority", ->(rooms){rooms.joined.where(low_priority: true)}],
  ["left",         "Left",         ->(rooms){rooms.where(membership: "leave")}],
].freeze

Inertia.share do
  sections = SECTIONS.map do |key, title, select|
    rooms = select.call(Models::Matrix::Room.dataset).by_activity.all

    {
      key:      key,
      title:    title,
      rooms:    rooms.map do |room|
        {
          roomId:        room.room_id,
          title:         room.title,
          avatarUrl:     room.avatar_url,
          topic:         room.topic,
          preview:       room.preview,
          previewSender: room.preview_sender,
          unread:        room.num_unread.to_i,
          highlight:     room.num_mentions.to_i,
          markedUnread:  room.marked_unread,
          direct:        room.direct,
          encrypted:     room.encrypted,
          membership:    room.membership,
          lastActivity:  room.last_activity_at,
        }
      end,
      # The badge on the section header, which is the sum of its rooms rather
      # than a count of them.
      unread:   rooms.sum{|room| room.num_unread.to_i},
      # Left is the one section nobody wants open by default.
      expanded: key != "left",
    }
  end

  { matrix: { sections: sections.reject{|section| section[:rooms].empty?} } }
end

__END__

import { Link, usePage } from "@inertiajs/react"
import { useMemo, useState, type ReactNode } from "react"
import { ChevronRight, Compass, Hash, Lock, Plus, Search, Settings, ShieldCheck, X } from "lucide-react"

import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Badge } from "@/components/reui/badge"
import { Button } from "@/components/ui/button"
import { Collapsible, CollapsibleContent, CollapsibleTrigger } from "@/components/ui/collapsible"
import { Empty, EmptyDescription, EmptyHeader, EmptyTitle } from "@/components/ui/empty"
import { Input } from "@/components/ui/input"
import { ScrollArea } from "@/components/ui/scroll-area"
import { Tooltip, TooltipContent, TooltipTrigger } from "@/components/ui/tooltip"
import { ShellSidebar } from "@/components/admin/slots"
import { cn } from "cn"

type Room = {
  roomId: string
  title: string
  avatarUrl: string | null
  topic: string | null
  preview: string | null
  previewSender: string | null
  unread: number
  highlight: number
  markedUnread: boolean
  direct: boolean
  encrypted: boolean
  membership: string
  lastActivity: number | null
}

type Section = {
  key: string
  title: string
  rooms: Room[]
  unread: number
  expanded: boolean
}

// Fractal names a room after its heroes when it has no m.room.name, so a title
// is never empty -- the initial is just its first character.
const initial = (title: string) => title.replace(/^[#!@]/, "").charAt(0).toUpperCase()

function RoomRow({ room, active }: { room: Room; active: boolean }) {
  // HIGHLIGHT AND UNREAD ARE DIFFERENT THINGS. A highlight is a mention and is
  // always loud; an unread count is not. HighlightFlags separates them for the
  // same reason, and collapsing the two makes every busy room look urgent.
  const loud = room.highlight > 0
  const unread = room.unread > 0 || room.markedUnread

  return (
    <Link
      href={`/matrix/rooms/${encodeURIComponent(room.roomId)}`}
      className={cn(
        "flex w-full items-center gap-2.5 rounded-md px-2 py-1.5 text-left text-sm transition-colors",
        active ? "bg-accent text-accent-foreground" : "hover:bg-accent/50"
      )}
    >
      <Avatar className="size-7 shrink-0">
        {room.avatarUrl && <AvatarImage src={room.avatarUrl} alt="" />}
        <AvatarFallback className="text-[11px]">{initial(room.title)}</AvatarFallback>
      </Avatar>

      <div className="flex min-w-0 flex-1 flex-col">
        <div className="flex min-w-0 items-center gap-1">
          <span className={cn("truncate", unread && "font-semibold")}>{room.title}</span>
          {room.encrypted && (
            <Lock className="size-3 shrink-0 text-muted-foreground" aria-label="Encrypted" />
          )}
        </div>
        {room.preview && (
          <span className="truncate text-xs text-muted-foreground">
            {room.previewSender ? `${room.previewSender}: ` : ""}
            {room.preview}
          </span>
        )}
      </div>

      {loud ? (
        <Badge variant="destructive" size="sm" radius="full">
          {room.highlight}
        </Badge>
      ) : room.unread > 0 ? (
        <Badge variant="secondary" size="sm" radius="full">
          {room.unread}
        </Badge>
      ) : room.markedUnread ? (
        <span className="size-2 shrink-0 rounded-full bg-primary" aria-label="Unread" />
      ) : null}
    </Link>
  )
}

function SidebarSection({ section, activeRoomId }: { section: Section; activeRoomId: string | null }) {
  return (
    <Collapsible defaultOpen={section.expanded} className="group/section">
      <CollapsibleTrigger className="flex w-full items-center gap-1 px-2 py-1 text-xs font-medium text-muted-foreground hover:text-foreground">
        <ChevronRight className="size-3 transition-transform group-data-[state=open]/section:rotate-90" />
        <span className="flex-1 text-left">{section.title}</span>
        {section.unread > 0 && <span className="tabular-nums">{section.unread}</span>}
      </CollapsibleTrigger>

      <CollapsibleContent className="flex flex-col gap-0.5 pb-2">
        {section.rooms.map((room) => (
          <RoomRow key={room.roomId} room={room} active={room.roomId === activeRoomId} />
        ))}
      </CollapsibleContent>
    </Collapsible>
  )
}

// Fractal's room_search over the one list. Filtering here rather than on the
// server because the whole list is already in the page -- a keystroke that
// costs a round trip is a keystroke that lags.
function filterSections(sections: Section[], query: string) {
  const needle = query.trim().toLowerCase()

  if (!needle) return sections

  return sections
    .map((section) => ({
      ...section,
      rooms: section.rooms.filter((room) => room.title.toLowerCase().includes(needle)),
      // Open every section that still has a hit: a match hidden inside a
      // collapsed section reads as no match at all.
      expanded: true,
    }))
    .filter((section) => section.rooms.length > 0)
}

export default function MatrixLayout({ children }: { children: ReactNode }) {
  const page = usePage<{ matrix: { sections: Section[] } }>()
  const sections = page.props.matrix?.sections ?? []
  const [query, setQuery] = useState("")

  const shown = useMemo(() => filterSections(sections, query), [sections, query])
  const unread = sections.reduce((total, section) => total + section.unread, 0)

  // The room in the URL, decoded -- room ids carry ! and : and arrive encoded.
  const match = page.url.match(/^\/matrix\/rooms\/([^/?]+)/)
  const activeRoomId = match ? decodeURIComponent(match[1]) : null

  // LOGIN RENDERS BARE. Fractal's Window shows either Login or SessionView and
  // never both, and the reason is not cosmetic: before a device exists there
  // is no room list to put beside it, so the sidebar would be an empty pane
  // framing the one control that matters. No ShellSidebar here, so the shell's
  // panel stays collapsed and the sidebar is the icon rail alone.
  if (page.component === "matrix/login") {
    return <div className="flex min-h-0 flex-1 flex-col">{children}</div>
  }

  return (
    <>
      {/* THE ROOM LIST GOES IN THE SHELL'S SIDEBAR, NOT BESIDE IT. This is
          Adw.NavigationSplitView's sidebar half, and the split it wants is the
          one the shell already draws: rail | list | content. Rendered as an
          <aside> of its own it came out as a third column inside the content
          pane, under the shell's header -- a layout nested in a layout. */}
      <ShellSidebar>
        {/* The panel's own header, on the shell's header grid so the two line
            up across the split. */}
        <div className="border-border flex h-(--header-height) shrink-0 items-center justify-between gap-2 border-b px-3">
          <div className="flex min-w-0 items-center gap-2">
            <span className="text-sm leading-relaxed font-semibold">Matrix</span>
            {unread > 0 && (
              <Badge className="rounded-full!" variant="outline" size="sm">
                {unread}
              </Badge>
            )}
          </div>

          <div className="flex items-center gap-0.5">
            <Tooltip>
              <TooltipTrigger
                render={
                  <Button
                    variant="ghost"
                    size="icon-sm"
                    aria-label="New room"
                    nativeButton={false}
                    render={<Link href="/matrix/rooms/new" />}
                  />
                }
              >
                <Plus aria-hidden="true" />
              </TooltipTrigger>
              <TooltipContent>New room</TooltipContent>
            </Tooltip>

            <Tooltip>
              <TooltipTrigger
                render={
                  <Button
                    variant="ghost"
                    size="icon-sm"
                    aria-label="Explore rooms"
                    nativeButton={false}
                    render={<Link href="/matrix/explore" />}
                  />
                }
              >
                <Compass aria-hidden="true" />
              </TooltipTrigger>
              <TooltipContent>Explore</TooltipContent>
            </Tooltip>

            <Tooltip>
              <TooltipTrigger
                render={
                  <Button
                    variant="ghost"
                    size="icon-sm"
                    aria-label="Verification"
                    nativeButton={false}
                    render={<Link href="/matrix/verification" />}
                  />
                }
              >
                <ShieldCheck aria-hidden="true" />
              </TooltipTrigger>
              <TooltipContent>Verification</TooltipContent>
            </Tooltip>

            <Tooltip>
              <TooltipTrigger
                render={
                  <Button
                    variant="ghost"
                    size="icon-sm"
                    aria-label="Matrix settings"
                    nativeButton={false}
                    render={<Link href="/matrix/settings" />}
                  />
                }
              >
                <Settings aria-hidden="true" />
              </TooltipTrigger>
              <TooltipContent>Settings</TooltipContent>
            </Tooltip>
          </div>
        </div>

        {/* Gtk.SearchBar */}
        <div className="border-border/60 border-b px-3 py-2">
          <div className="relative">
            <Search
              className="text-muted-foreground/50 pointer-events-none absolute top-1/2 left-2.5 size-3 -translate-y-1/2"
              aria-hidden="true"
            />
            <Input
              placeholder="Search rooms..."
              value={query}
              onChange={(event) => setQuery(event.target.value)}
              className="h-7 pl-7 text-xs"
              aria-label="Search rooms"
            />
            {query && (
              <Button
                variant="ghost"
                size="icon-xs"
                onClick={() => setQuery("")}
                aria-label="Clear search"
                className="text-muted-foreground/50 hover:text-foreground absolute top-1/2 right-1 size-5 -translate-y-1/2"
              >
                <X aria-hidden="true" />
              </Button>
            )}
          </div>
        </div>

        {/* SidebarItemList */}
        <ScrollArea className="min-h-0 flex-1">
          <div className="flex flex-col gap-1 p-2">
            {shown.length === 0 ? (
              <Empty className="py-8">
                <EmptyHeader>
                  <EmptyTitle className="text-sm">{query ? "No matches" : "No rooms"}</EmptyTitle>
                  <EmptyDescription className="text-xs">
                    {query
                      ? "No room name matches that search."
                      : "Rooms appear here once the device has synced."}
                  </EmptyDescription>
                </EmptyHeader>
              </Empty>
            ) : (
              shown.map((section) => (
                <SidebarSection key={section.key} section={section} activeRoomId={activeRoomId} />
              ))
            )}
          </div>
        </ScrollArea>

        <div className="border-border/60 flex items-center gap-1 border-t p-2 text-xs">
          <Link href="/matrix/rooms/direct" className="rounded px-2 py-1 hover:bg-accent">
            <Hash className="mr-1 inline size-3" />
            New direct chat
          </Link>
        </div>
      </ShellSidebar>

      {/* The content half. The page's header goes in the shell's header bar
          through <ShellHeader>, so there is no header here. */}
      <div className="flex min-h-0 min-w-0 flex-1 flex-col">{children}</div>
    </>
  )
}
