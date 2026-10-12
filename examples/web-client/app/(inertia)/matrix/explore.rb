# frozen_string_literal: true

# /matrix/explore — Explore
#
# Fractal: session_view/explore/ (+ servers_popover, server_list)
#
# NOT IMPLEMENTED.
#
# The public room directory: /publicRooms against the homeserver and any
# custom servers, with join/knock per row.
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
# session_view/explore/mod.blp
#
#   <Adw.BreakpointBin id="ContentExplore">
#     <Adw.ToolbarView slot="child">
#       <Adw.HeaderBar id="header_bar">
#         <Adw.Clamp id="search_clamp">
#           <Gtk.SearchEntry slot="child" id="search_entry" />
#         </Adw.Clamp>
#         <Gtk.MenuButton id="servers_button">
#           <ExploreServersPopover slot="popover" id="servers_popover" />
#         </Gtk.MenuButton>
#       </Adw.HeaderBar>
#       <Adw.Bin id="second_top_bar" />
#       <Gtk.Stack slot="content" id="stack">
#         <Gtk.StackPage>
#           <Adw.Spinner slot="child" />
#         </Gtk.StackPage>
#         <Gtk.StackPage>
#           <Adw.StatusPage slot="child" />
#         </Gtk.StackPage>
#         <Gtk.StackPage>
#           <Gtk.ScrolledWindow slot="child" id="scrolled_window">
#             <Adw.ClampScrollable slot="child">
#               <Gtk.ListView slot="child" id="listview" />
#             </Adw.ClampScrollable>
#           </Gtk.ScrolledWindow>
#         </Gtk.StackPage>
#         <Gtk.StackPage>
#           <Adw.StatusPage slot="child" />
#         </Gtk.StackPage>
#       </Gtk.Stack>
#     </Adw.ToolbarView>
#     <Adw.Breakpoint />
#   </Adw.BreakpointBin>
#
# session_view/explore/public_room_row.blp
#
#   <Adw.Bin id="PublicRoomRow">
#     <Gtk.Box slot="child">
#       <Avatar id="avatar" />
#       <Gtk.Box>
#         <Gtk.Label id="display_name" />
#         <Gtk.Label id="description" />
#         <Gtk.Label id="alias" />
#         <Gtk.Box>
#           <LoadingButton id="button" />
#           <Gtk.Box id="members_count_box">
#             <Gtk.Image />
#             <Gtk.Label id="members_count" />
#           </Gtk.Box>
#         </Gtk.Box>
#       </Gtk.Box>
#     </Gtk.Box>
#   </Adw.Bin>
#
# session_view/explore/servers_popover.blp
#
#   <Gtk.Popover id="ExploreServersPopover">
#     <Gtk.ScrolledWindow slot="child" id="scrolled_window">
#       <Gtk.Box slot="child">
#         <Gtk.ListBox id="listbox" />
#         <Gtk.Separator />
#         <Gtk.Box>
#           <Gtk.Entry id="server_entry" />
#           <Gtk.Button />
#         </Gtk.Box>
#       </Gtk.Box>
#     </Gtk.ScrolledWindow>
#   </Gtk.Popover>
#
# session_view/explore/server_row.blp
#
#   <Gtk.ListBoxRow id="ExploreServerRow">
#     <Gtk.Box slot="child">
#       <Gtk.Label />
#       <Gtk.Button id="remove_button" />
#     </Gtk.Box>
#   </Gtk.ListBoxRow>
#
# ── Build with ─────────────────────────────────────────────────────────────
#
# @reui/list-8 — "Integrations directory list with brand logos and per-row Connect
#   buttons". A public-room directory is that list with Join where Connect is: avatar,
#   name, topic, member count, one action per row.
#
#   Gtk.SearchEntry             ->  ui/input-group with a leading search icon
#   PublicRoomRow               ->  ui/item — avatar, name, topic, member count, Join button
#   ServersPopover / ServerRow  ->  ui/combobox — pick or add a server
#   Gtk.ListView (paged)        ->  ui/scroll-area + infinite scroll; /publicRooms is cursor-paged
#   no results                  ->  ui/empty
#
# The public room directory. Results come from the homeserver rather than the
# database -- nothing here is ours until we join it -- so the local room list
# is only consulted to mark what we are already in.
get "/" do
  render(
    "matrix/explore",
    query:  params["q"].to_s,
    server: params["server"].to_s,
    # Rooms we are already in, so a row offers Open rather than Join.
    joined: Models::Matrix::Room
      .where(user_id: matrix_user_id, membership: "join")
      .select_map(:room_id),
    results: [],
  )
end

__END__

import { Head, Link, router } from "@inertiajs/react"
import { useState } from "react"
import { Globe, Lock, Search, Users } from "lucide-react"

import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Badge } from "@/components/reui/badge"
import { Button } from "@/components/ui/button"
import { Empty, EmptyDescription, EmptyHeader, EmptyMedia, EmptyTitle } from "@/components/ui/empty"
import {
  InputGroup,
  InputGroupAddon,
  InputGroupInput,
} from "@/components/ui/input-group"
import { Item, ItemContent, ItemDescription, ItemMedia, ItemTitle } from "@/components/ui/item"
import { ScrollArea } from "@/components/ui/scroll-area"
import { ShellHeader } from "@/components/admin/slots"

type PublicRoom = {
  roomId: string
  name: string | null
  topic: string | null
  alias: string | null
  avatarUrl: string | null
  members: number
  worldReadable: boolean
  guestCanJoin: boolean
}

const initial = (name: string) => name.replace(/^[#!@]/, "").charAt(0).toUpperCase()

export default function MatrixExplore({
  query,
  server,
  joined,
  results,
}: {
  query: string
  server: string
  joined: string[]
  results: PublicRoom[]
}) {
  const [draft, setDraft] = useState(query)

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title="Explore · matrix" />

      <ShellHeader>
        <Globe className="size-4 text-muted-foreground" />
        <h1 className="text-sm font-medium">Explore</h1>
      </ShellHeader>

      <div className="border-b p-3">
        <div className="mx-auto flex w-full max-w-3xl gap-2">
          <InputGroup className="flex-1">
            <InputGroupAddon>
              <Search className="size-3.5" />
            </InputGroupAddon>
            <InputGroupInput
              value={draft}
              onChange={(event) => setDraft(event.target.value)}
              onKeyDown={(event) => {
                if (event.key === "Enter") {
                  router.get("/matrix/explore", { q: draft, server }, { preserveState: false })
                }
              }}
              placeholder="Search public rooms"
            />
          </InputGroup>
          {/* The server to ask. A directory is per-homeserver, so this is part
              of the query rather than a preference. */}
          <InputGroup className="w-56">
            <InputGroupAddon>Server</InputGroupAddon>
            <InputGroupInput
              defaultValue={server}
              placeholder="this server"
              onKeyDown={(event) => {
                if (event.key === "Enter") {
                  router.get(
                    "/matrix/explore",
                    { q: draft, server: event.currentTarget.value },
                    { preserveState: false }
                  )
                }
              }}
            />
          </InputGroup>
        </div>
      </div>

      <ScrollArea className="min-h-0 flex-1">
        <div className="mx-auto w-full max-w-3xl p-4">
          {results.length === 0 ? (
            <Empty className="py-12">
              <EmptyHeader>
                <EmptyMedia variant="icon">
                  <Globe />
                </EmptyMedia>
                <EmptyTitle>{query ? "No rooms found" : "Search the directory"}</EmptyTitle>
                <EmptyDescription>
                  {query
                    ? `Nothing published matches "${query}".`
                    : "Public rooms published by a homeserver appear here."}
                </EmptyDescription>
              </EmptyHeader>
            </Empty>
          ) : (
            <div className="flex flex-col gap-1">
              {results.map((room) => {
                const already = joined.includes(room.roomId)
                const title = room.name ?? room.alias ?? room.roomId

                return (
                  <Item key={room.roomId}>
                    <ItemMedia>
                      <Avatar className="size-9">
                        {room.avatarUrl && <AvatarImage src={room.avatarUrl} alt="" />}
                        <AvatarFallback>{initial(title)}</AvatarFallback>
                      </Avatar>
                    </ItemMedia>
                    <ItemContent>
                      <ItemTitle className="flex items-center gap-1.5">
                        {title}
                        {!room.worldReadable && (
                          <Lock className="size-3 text-muted-foreground" aria-label="History not public" />
                        )}
                      </ItemTitle>
                      <ItemDescription className="line-clamp-1">
                        {room.topic ?? room.alias ?? room.roomId}
                      </ItemDescription>
                    </ItemContent>
                    <div className="flex shrink-0 items-center gap-2">
                      <Badge variant="outline" size="sm">
                        <Users className="size-2.5" />
                        {room.members}
                      </Badge>
                      {already ? (
                        <Button size="sm" variant="outline" nativeButton={false} render={<Link href={`/matrix/rooms/${encodeURIComponent(room.roomId)}`} />}>Open</Button>
                      ) : (
                        <Button size="sm">Join</Button>
                      )}
                    </div>
                  </Item>
                )
              })}
            </div>
          )}
        </div>
      </ScrollArea>
    </div>
  )
}
