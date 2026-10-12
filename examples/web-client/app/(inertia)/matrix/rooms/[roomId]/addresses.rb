# frozen_string_literal: true

# /matrix/rooms/:roomId/addresses — Addresses
#
# Fractal: room_details/addresses_subpage/
#
# NOT IMPLEMENTED.
#
# The canonical alias and alt_aliases, plus registering and releasing local
# aliases.
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
# session_view/room_details/addresses_subpage/mod.blp
#
#   <Adw.NavigationPage id="RoomDetailsAddressesSubpage">
#     <Adw.ToolbarView slot="child">
#       <Adw.HeaderBar />
#       <Adw.PreferencesPage slot="content">
#         <Adw.PreferencesGroup id="public_addresses_group">
#           <Gtk.ListBox id="public_addresses_list" />
#           <Gtk.Revealer id="public_addresses_error_revealer">
#             <Gtk.Label slot="child" id="public_addresses_error" />
#           </Gtk.Revealer>
#         </Adw.PreferencesGroup>
#         <Adw.PreferencesGroup id="local_addresses_group">
#           <Gtk.ListBox id="local_addresses_list" />
#           <Gtk.Revealer id="local_addresses_error_revealer">
#             <Gtk.Label slot="child" id="local_addresses_error" />
#           </Gtk.Revealer>
#         </Adw.PreferencesGroup>
#       </Adw.PreferencesPage>
#     </Adw.ToolbarView>
#   </Adw.NavigationPage>
#   <EntryAddRow id="public_addresses_add_row" />
#   <SubstringEntryRow id="local_addresses_add_row" />
#
# session_view/room_details/addresses_subpage/completion_popover.blp
#
#   <Gtk.Popover id="RoomDetailsAddressesSubpageCompletionPopover">
#     <Gtk.ScrolledWindow slot="child" id="scrolled_window">
#       <Gtk.ListBox slot="child" id="list" />
#     </Gtk.ScrolledWindow>
#   </Gtk.Popover>
#
# ── Build with ─────────────────────────────────────────────────────────────
#
# @reui/settings-8 — "Webhook endpoints settings list with per-endpoint delivery-health
#   alerts and enable toggle". A list you add to, remove from, and mark one of as
#   primary -- which is the canonical alias.
#
#   EntryAddRow        ->  ui/input-group with a trailing Add button
#   RemovableRow       ->  ui/item with a destructive trailing button
#   canonical vs alt   ->  ui/badge marking the canonical one
#   CompletionPopover  ->  reui/autocomplete — :server suffix completion
#   publish toggle     ->  ui/switch
#
# INSTALL, reui registry: @reui/autocomplete
#
# The canonical alias and the published alt_aliases.
get "/" do
  room = matrix_room!
  canonical = matrix_state(room, "m.room.canonical_alias")

  render(
    "matrix/rooms/[roomId]/addresses",
    roomId:    room[:room_id],
    roomTitle: matrix_room_title(room),
    canonical: room[:canonical_alias] || canonical["alias"],
    alt:       Array(room[:alt_aliases].to_a | Array(canonical["alt_aliases"])).compact.uniq,
  )
end

post "/" do
  halt(501, "matrix: not implemented\n")
end

__END__

import { Form, Head, Link } from "@inertiajs/react"
import { ArrowLeft, Plus, Star, Trash2 } from "lucide-react"

import { Badge } from "@/components/reui/badge"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Empty, EmptyDescription, EmptyHeader, EmptyTitle } from "@/components/ui/empty"
import {
  InputGroup,
  InputGroupAddon,
  InputGroupButton,
  InputGroupInput,
} from "@/components/ui/input-group"
import { ScrollArea } from "@/components/ui/scroll-area"
import { ShellHeader } from "@/components/admin/slots"

export default function MatrixRoomAddresses({
  roomId,
  roomTitle,
  canonical,
  alt,
}: {
  roomId: string
  roomTitle: string
  canonical: string | null
  alt: string[]
}) {
  const encoded = encodeURIComponent(roomId)
  const all = [...(canonical ? [canonical] : []), ...alt.filter((a) => a !== canonical)]

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title={`Addresses · ${roomTitle}`} />

      <ShellHeader>
        <Link href={`/matrix/rooms/${encoded}/about`} className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">Addresses</h1>
      </ShellHeader>

      <ScrollArea className="min-h-0 flex-1">
        <div className="mx-auto flex w-full max-w-2xl flex-col gap-4 p-6">
          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Published addresses</CardTitle>
              <CardDescription>
                The starred one is the canonical address, which is how the room names itself.
              </CardDescription>
            </CardHeader>
            <CardContent className="flex flex-col gap-1">
              {all.length === 0 ? (
                <Empty className="py-8">
                  <EmptyHeader>
                    <EmptyTitle className="text-sm">No addresses</EmptyTitle>
                    <EmptyDescription className="text-xs">
                      A room with no address can only be joined by invite or by id.
                    </EmptyDescription>
                  </EmptyHeader>
                </Empty>
              ) : (
                all.map((address) => (
                  <div
                    key={address}
                    className="flex items-center gap-2 rounded-md px-2 py-1.5 hover:bg-accent/50"
                  >
                    <code className="flex-1 truncate font-mono text-sm">{address}</code>
                    {address === canonical ? (
                      <Badge variant="secondary" size="sm">
                        <Star className="size-2.5" />
                        Main
                      </Badge>
                    ) : (
                      <Button variant="ghost" size="icon-xs" aria-label="Make main">
                        <Star className="size-3.5" />
                      </Button>
                    )}
                    <Button variant="ghost" size="icon-xs" aria-label="Remove">
                      <Trash2 className="size-3.5 text-destructive" />
                    </Button>
                  </div>
                ))
              )}
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Add an address</CardTitle>
              <CardDescription>
                The local part only. The server suffix is added for you.
              </CardDescription>
            </CardHeader>
            <CardContent>
              <Form action={`/matrix/rooms/${encoded}/addresses`} method="post">
                <InputGroup>
                  <InputGroupAddon>#</InputGroupAddon>
                  <InputGroupInput name="alias" placeholder="room-name" />
                  <InputGroupAddon align="inline-end">
                    <InputGroupButton type="submit" size="xs">
                      <Plus className="size-3.5" />
                      Add
                    </InputGroupButton>
                  </InputGroupAddon>
                </InputGroup>
              </Form>
            </CardContent>
          </Card>
        </div>
      </ScrollArea>
    </div>
  )
}
