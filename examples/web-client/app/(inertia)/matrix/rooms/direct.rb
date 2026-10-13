# frozen_string_literal: true

# /matrix/rooms/direct — New direct chat
#
# Fractal: session_view/create_direct_chat_dialog/
#
# Start a DM: user search, then /createRoom with is_direct and the m.direct
# account-data update.
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
# session_view/create_direct_chat_dialog/mod.blp
#
#   <Adw.Dialog id="CreateDirectChatDialog">
#     <Adw.ToolbarView slot="child">
#       <Adw.HeaderBar />
#       <Adw.Clamp>
#         <Gtk.Box>
#           <Gtk.Label id="heading" />
#           <Gtk.SearchEntry id="search_entry" />
#         </Gtk.Box>
#       </Adw.Clamp>
#       <Gtk.Stack slot="content" id="stack">
#         <Gtk.StackPage>
#           <Adw.StatusPage slot="child" />
#         </Gtk.StackPage>
#         <Gtk.StackPage>
#           <Gtk.ScrolledWindow slot="child" id="matching_page">
#             <Adw.Clamp slot="child">
#               <Gtk.ListBox slot="child" id="list_box" />
#             </Adw.Clamp>
#           </Gtk.ScrolledWindow>
#         </Gtk.StackPage>
#         <Gtk.StackPage>
#           <Adw.StatusPage slot="child" />
#         </Gtk.StackPage>
#         <Gtk.StackPage>
#           <Adw.StatusPage slot="child" id="error_page" />
#         </Gtk.StackPage>
#         <Gtk.StackPage>
#           <Adw.Spinner slot="child" />
#         </Gtk.StackPage>
#       </Gtk.Stack>
#     </Adw.ToolbarView>
#   </Adw.Dialog>
#
# ── Build with ─────────────────────────────────────────────────────────────
#
# @reui/dialog-2 — "Workspace invite dialog with multi-email input and role select".
#   The multi-value entry is the part worth taking; roles are not in play here.
#
#   Gtk.SearchEntry + results  ->  reui/autocomplete — async /user_directory/search
#   selected users as pills    ->  ui/badge chips with a remove affordance
#   Pill (components/pill)     ->  ui/badge + ui/avatar
#
# INSTALL, reui registry: @reui/autocomplete
#
get "/" do
  render("matrix/rooms/direct")
end

post "/" do
  act! do
    room_id = Matrix::RoomActions.create_direct(params["user_id"].to_s)

    redirect("/matrix/rooms/#{CGI.escape(room_id)}", 303)
  end
end

__END__

import { Form, Head, Link } from "@inertiajs/react"
import { ArrowLeft, Search } from "lucide-react"

import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Empty, EmptyDescription, EmptyHeader, EmptyTitle } from "@/components/ui/empty"
import {
  InputGroup,
  InputGroupAddon,
  InputGroupInput,
} from "@/components/ui/input-group"
import { ScrollArea } from "@/components/ui/scroll-area"
import { ShellHeader } from "@/components/admin/slots"

export default function MatrixNewDirect() {
  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title="New direct chat · matrix" />

      <ShellHeader>
        <Link href="/matrix" className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="text-sm font-medium">New direct chat</h1>
      </ShellHeader>

      <ScrollArea className="min-h-0 flex-1">
        <div className="mx-auto flex w-full max-w-xl flex-col gap-4 p-6">
          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Who</CardTitle>
              <CardDescription>
                Search the directory, or type a full Matrix ID for somebody on another server.
              </CardDescription>
            </CardHeader>
            <CardContent className="flex flex-col gap-3">
              <Form action="/matrix/rooms/direct" method="post" className="flex flex-col gap-3">
                <InputGroup>
                  <InputGroupAddon>
                    <Search className="size-3.5" />
                  </InputGroupAddon>
                  <InputGroupInput name="user_id" placeholder="@alice:example.org" autoFocus />
                </InputGroup>
                <Button type="submit" className="self-start">
                  Start chat
                </Button>
              </Form>

              <Empty className="py-8">
                <EmptyHeader>
                  <EmptyTitle className="text-sm">No results yet</EmptyTitle>
                  <EmptyDescription className="text-xs">
                    Directory results appear here as you type.
                  </EmptyDescription>
                </EmptyHeader>
              </Empty>
            </CardContent>
          </Card>
        </div>
      </ScrollArea>
    </div>
  )
}
