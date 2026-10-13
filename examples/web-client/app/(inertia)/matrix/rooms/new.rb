# frozen_string_literal: true

# /matrix/rooms/new — New room
#
# Fractal: session_view/create_room_dialog.blp
#
# Create a room: name, topic, visibility, encryption. A dialog in Fractal, a
# page here -- this router has no modal concept and the house pattern for a
# form that commits is get + post on one route (see app/labels/new.rb).
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
# session_view/create_room_dialog.blp
#
#   <ToastableDialog id="CreateRoomDialog">
#     <Adw.ToolbarView slot="child-content">
#       <Adw.HeaderBar />
#       <Gtk.ScrolledWindow slot="content" id="scrolled_window">
#         <Adw.Clamp slot="child">
#           <Gtk.Box slot="child">
#             <Gtk.Label id="heading" />
#             <Gtk.Box id="content">
#               <Adw.PreferencesGroup>
#                 <Adw.EntryRow id="room_name" />
#               </Adw.PreferencesGroup>
#               <Adw.PreferencesGroup id="topic_group">
#                 <Gtk.ScrolledWindow>
#                   <Gtk.TextView id="topic_text_view" />
#                 </Gtk.ScrolledWindow>
#               </Adw.PreferencesGroup>
#               <Adw.PreferencesGroup>
#                 <Adw.ActionRow>
#                   <Gtk.CheckButton id="visibility_private" />
#                 </Adw.ActionRow>
#                 <Adw.ActionRow>
#                   <Gtk.CheckButton id="visibility_public" />
#                 </Adw.ActionRow>
#               </Adw.PreferencesGroup>
#               <Adw.PreferencesGroup>
#                 <Adw.SwitchRow id="encryption" />
#               </Adw.PreferencesGroup>
#               <Adw.PreferencesGroup>
#                 <SubstringEntryRow id="room_address" />
#                 <Gtk.Revealer id="room_address_error_revealer">
#                   <Gtk.Label slot="child" id="room_address_error" />
#                 </Gtk.Revealer>
#               </Adw.PreferencesGroup>
#             </Gtk.Box>
#             <LoadingButton id="create_button" />
#           </Gtk.Box>
#         </Adw.Clamp>
#       </Gtk.ScrolledWindow>
#     </Adw.ToolbarView>
#   </ToastableDialog>
#
# ── Build with ─────────────────────────────────────────────────────────────
#
# @reui/dialog-9 — "Create project dialog with cover image upload and status, priority,
#   assignee, and label comboboxes". Same shape as create-room: avatar upload, name,
#   topic, and a few enumerated choices. Rendered as a page, not a dialog.
#
#   Adw.EntryRow (name/topic)  ->  ui/field + ui/input / ui/textarea
#   EditableAvatar             ->  ui/avatar + file-upload
#   visibility / preset        ->  ui/radio-group — three mutually exclusive choices, not a select
#   encryption switch          ->  ui/switch
#   Adw.PreferencesGroup       ->  ui/card or reui/frame
#
# INSTALL, plain shadcn: radio-group
# INSTALL, NOT IN EITHER REGISTRY -- reui lists file-upload on its components page but the
#   base-vega registry does not carry it; check the name before relying on it.
#
get "/" do
  render("matrix/rooms/new")
end

post "/" do
  act! do
    payload = {
      name:   params["name"].to_s,
      topic:  params["topic"].to_s,
      preset: params.fetch("preset", "private_chat").to_s,
    }.reject{|_key, value| value.to_s.empty?}

    unless params["alias"].to_s.empty?
      payload[:room_alias_name] = params["alias"].to_s
    end

    if params["encrypted"] == "true"
      payload[:initial_state] = [
        { type: "m.room.encryption", state_key: "", content: { algorithm: "m.megolm.v1.aes-sha2" } },
      ]
    end

    room_id = Matrix::RoomActions.create_room(**payload)

    redirect("/matrix/rooms/#{CGI.escape(room_id)}", 303)
  end
end

__END__

import { Form, Head, Link } from "@inertiajs/react"
import { ArrowLeft } from "lucide-react"

import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group"
import { ScrollArea } from "@/components/ui/scroll-area"
import { Switch } from "@/components/ui/switch"
import { Textarea } from "@/components/ui/textarea"
import { ShellHeader } from "@/components/admin/slots"

export default function MatrixNewRoom() {
  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title="New room · matrix" />

      <ShellHeader>
        <Link href="/matrix" className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="text-sm font-medium">New room</h1>
      </ShellHeader>

      <ScrollArea className="min-h-0 flex-1">
        <Form
          action="/matrix/rooms/new"
          method="post"
          className="mx-auto flex w-full max-w-xl flex-col gap-4 p-6"
        >
          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Details</CardTitle>
            </CardHeader>
            <CardContent className="flex flex-col gap-4">
              <div className="flex flex-col gap-2">
                <Label htmlFor="name">Name</Label>
                <Input id="name" name="name" placeholder="Ops" autoFocus />
              </div>
              <div className="flex flex-col gap-2">
                <Label htmlFor="topic">Topic</Label>
                <Textarea id="topic" name="topic" rows={2} placeholder="What the room is for" />
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Visibility</CardTitle>
              <CardDescription>This sets the join rule and whether it is published.</CardDescription>
            </CardHeader>
            <CardContent>
              <RadioGroup name="visibility" defaultValue="private" className="gap-3">
                <div className="flex items-start gap-3">
                  <RadioGroupItem value="private" id="v-private" className="mt-0.5" />
                  <div className="flex flex-col gap-0.5">
                    <Label htmlFor="v-private" className="font-normal">Private</Label>
                    <span className="text-xs text-muted-foreground">Invite only, unlisted.</span>
                  </div>
                </div>
                <div className="flex items-start gap-3">
                  <RadioGroupItem value="public" id="v-public" className="mt-0.5" />
                  <div className="flex flex-col gap-0.5">
                    <Label htmlFor="v-public" className="font-normal">Public</Label>
                    <span className="text-xs text-muted-foreground">
                      Anyone can join and it is published in the directory.
                    </span>
                  </div>
                </div>
              </RadioGroup>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Encryption</CardTitle>
              <CardDescription>
                {/* Irreversible, and the spec gives no way back -- worth saying
                    at the point of choosing rather than afterwards. */}
                Encryption cannot be turned off once a room has it.
              </CardDescription>
            </CardHeader>
            <CardContent className="flex items-center justify-between gap-4">
              <Label htmlFor="encrypted" className="font-normal">
                Enable end-to-end encryption
              </Label>
              <Switch id="encrypted" name="encrypted" defaultChecked />
            </CardContent>
          </Card>

          <Button type="submit" className="self-start">
            Create room
          </Button>
        </Form>
      </ScrollArea>
    </div>
  )
}
