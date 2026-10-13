# frozen_string_literal: true

# /matrix/settings/safety — Safety
#
# Fractal: account_settings/safety_page/ (+ ignored_users_subpage/)
#
# NOT IMPLEMENTED.
#
# The ignored user list, which lives in m.ignored_user_list -- so
# matrix_account_data, which is why it was unreachable before.
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
# account_settings/safety_page/mod.blp
#
#   <Adw.PreferencesPage id="SafetyPage">
#     <Adw.PreferencesGroup>
#       <ButtonCountRow id="ignored_users_row" />
#     </Adw.PreferencesGroup>
#     <Adw.PreferencesGroup>
#       <Adw.SwitchRow id="public_read_receipts_row" />
#       <Adw.SwitchRow id="typing_row" />
#     </Adw.PreferencesGroup>
#     <Adw.PreferencesGroup id="media_previews">
#       <CheckLoadingRow id="media_previews_on_row" />
#       <CheckLoadingRow id="media_previews_private_row" />
#       <CheckLoadingRow id="media_previews_off_row" />
#     </Adw.PreferencesGroup>
#     <Adw.PreferencesGroup>
#       <SwitchLoadingRow id="invite_avatars_row" />
#     </Adw.PreferencesGroup>
#   </Adw.PreferencesPage>
#
# account_settings/safety_page/ignored_users_subpage/mod.blp
#
#   <Adw.NavigationPage id="IgnoredUsersSubpage">
#     <Gtk.Stack id="stack">
#       <Gtk.StackPage>
#         <Adw.ToolbarView slot="child">
#           <Adw.HeaderBar>
#             <Gtk.ToggleButton id="search_button" />
#           </Adw.HeaderBar>
#           <Gtk.SearchBar id="search_bar">
#             <Adw.Clamp slot="child">
#               <Gtk.SearchEntry id="search_entry" />
#             </Adw.Clamp>
#           </Gtk.SearchBar>
#           <Gtk.ScrolledWindow slot="content">
#             <Adw.ClampScrollable slot="child">
#               <Gtk.ListView slot="child" id="list_view" />
#             </Adw.ClampScrollable>
#           </Gtk.ScrolledWindow>
#         </Adw.ToolbarView>
#       </Gtk.StackPage>
#       <Gtk.StackPage>
#         <Adw.ToolbarView slot="child">
#           <Adw.HeaderBar />
#           <Adw.StatusPage slot="content" />
#         </Adw.ToolbarView>
#       </Gtk.StackPage>
#     </Gtk.Stack>
#   </Adw.NavigationPage>
#
# account_settings/safety_page/ignored_users_subpage/ignored_user_row.blp
#
#   <Gtk.Box id="IgnoredUserRow">
#     <Gtk.Label id="title" />
#     <LoadingButton id="stop_ignoring_button" />
#   </Gtk.Box>
#
# ── Build with ─────────────────────────────────────────────────────────────
#
# @reui/settings-2 — "Privacy and preferences settings card with mixed-control rows,
#   switches, buttons and Pro/Beta badges". The ignored-user list is a removable-row
#   list under those preference rows.
#
#   IgnoredUsersSubpage              ->  ui/item rows with a destructive trailing button
#   IgnoredUserRow                   ->  ui/avatar + id + Unignore
#   empty list                       ->  ui/empty
#   media previews / invite avatars  ->  ui/radio-group (All / Private / None) + ui/switch
#
# INSTALL, plain shadcn: radio-group
#

get "/" do
  ignored = Models::Matrix::AccountData
    .content_for(event_type: Models::Matrix::AccountData::IGNORED_USERS).to_h
  previews = Models::Matrix::AccountData.content_for(event_type: "m.media_previews").to_h

  render(
    "matrix/settings/safety",
    ignored:        ignored["ignored_users"].to_h.keys.sort,
    mediaPreviews:  previews["media_previews"] || "private",
    inviteAvatars:  (previews["invite_avatars"] || "on") == "on",
    readReceipts:   Models::Matrix::AccountData
      .content_for(event_type: "m.read_receipts").to_h.fetch("enabled", true),
    typingNotices:  Models::Matrix::AccountData
      .content_for(event_type: "m.typing_notifications").to_h.fetch("enabled", true),
  )
end

post "/" do
  act! do
    case params["action"].to_s
    when "ignore"
      Matrix::RoomActions.ignore_user(params["user_id"].to_s)
    when "unignore"
      Matrix::RoomActions.unignore_user(params["user_id"].to_s)
    else
      Matrix::RoomActions.set_global_account_data(
        "m.media_previews",
        {
          "media_previews" => params.fetch("media_previews", "private").to_s,
          "invite_avatars" => params["invite_avatars"] == "true" ? "on" : "off",
        },
      )

      Matrix::RoomActions.set_global_account_data(
        "m.read_receipts", { "enabled" => params["read_receipts"] == "true" },
      )

      Matrix::RoomActions.set_global_account_data(
        "m.typing_notifications", { "enabled" => params["typing_notices"] == "true" },
      )
    end
  end
end

__END__

import { Head, Link } from "@inertiajs/react"
import { ArrowLeft, UserX } from "lucide-react"

import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Empty, EmptyDescription, EmptyHeader, EmptyTitle } from "@/components/ui/empty"
import { Label } from "@/components/ui/label"
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group"
import { ScrollArea } from "@/components/ui/scroll-area"
import { Switch } from "@/components/ui/switch"
import { ShellHeader } from "@/components/admin/slots"

const PREVIEWS = [
  { value: "on", label: "Show in all rooms" },
  { value: "private", label: "Show only in private rooms" },
  { value: "off", label: "Hide in all rooms" },
]

export default function MatrixSettingsSafety({
  ignored,
  mediaPreviews,
  inviteAvatars,
  readReceipts,
  typingNotices,
}: {
  ignored: string[]
  mediaPreviews: string
  inviteAvatars: boolean
  readReceipts: boolean
  typingNotices: boolean
}) {
  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title="Safety · matrix" />

      <ShellHeader>
        <Link href="/matrix/settings" className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="text-sm font-medium">Safety</h1>
      </ShellHeader>

      <ScrollArea className="min-h-0 flex-1">
        <div className="mx-auto flex w-full max-w-2xl flex-col gap-4 p-6">
          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Ignored Users</CardTitle>
              <CardDescription>
                {/* Ignoring hides history too, not just new messages -- the
                    server stops sending their events entirely. */}
                Their messages are hidden everywhere, including ones already sent, and their
                invites are dropped.
              </CardDescription>
            </CardHeader>
            <CardContent className="flex flex-col gap-1">
              {ignored.length === 0 ? (
                <Empty className="py-6">
                  <EmptyHeader>
                    <EmptyTitle className="text-sm">Nobody is ignored</EmptyTitle>
                    <EmptyDescription className="text-xs">
                      Ignore somebody from their profile.
                    </EmptyDescription>
                  </EmptyHeader>
                </Empty>
              ) : (
                ignored.map((userId) => (
                  <div
                    key={userId}
                    className="flex items-center gap-2 rounded-md px-2 py-1.5 hover:bg-accent/50"
                  >
                    <UserX className="size-4 shrink-0 text-muted-foreground" />
                    <Link
                      href={`/matrix/users/${encodeURIComponent(userId)}`}
                      className="flex-1 truncate font-mono text-sm hover:underline"
                    >
                      {userId}
                    </Link>
                    <Button variant="ghost" size="xs">
                      Unignore
                    </Button>
                  </div>
                ))
              )}
            </CardContent>
          </Card>

          {/* Fractal's Privacy group, with its subtitles verbatim: both are about what other
              people in a room can observe about you. */}
          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Privacy</CardTitle>
            </CardHeader>
            <CardContent className="flex flex-col gap-4">
              <div className="flex items-center justify-between gap-4">
                <div className="flex flex-col gap-0.5">
                  <Label htmlFor="read_receipts" className="font-normal">
                    Send Read Receipts
                  </Label>
                  <span className="text-xs text-muted-foreground">
                    Allow other members of the rooms you participate in to track which messages you
                    have seen
                  </span>
                </div>
                <Switch id="read_receipts" defaultChecked={readReceipts} />
              </div>

              <div className="flex items-center justify-between gap-4 border-t pt-4">
                <div className="flex flex-col gap-0.5">
                  <Label htmlFor="typing_notices" className="font-normal">
                    Send Typing Notifications
                  </Label>
                  <span className="text-xs text-muted-foreground">
                    Allow other members of the rooms you participate in to see when you are typing a
                    message
                  </span>
                </div>
                <Switch id="typing_notices" defaultChecked={typingNotices} />
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Media Previews</CardTitle>
              <CardDescription>
                Loading media tells the sender's server you opened the room.
              </CardDescription>
            </CardHeader>
            <CardContent className="flex flex-col gap-4">
              <RadioGroup defaultValue={mediaPreviews} className="gap-3">
                {PREVIEWS.map((option) => (
                  <div key={option.value} className="flex items-start gap-3">
                    <RadioGroupItem value={option.value} id={`p-${option.value}`} className="mt-0.5" />
                    <div className="flex flex-col gap-0.5">
                      <Label htmlFor={`p-${option.value}`} className="font-normal">
                        {option.label}
                      </Label>
                      <span className="text-xs text-muted-foreground">{option.hint}</span>
                    </div>
                  </div>
                ))}
              </RadioGroup>

              <div className="flex items-center justify-between gap-4 border-t pt-4">
                <div className="flex flex-col gap-0.5">
                  <Label htmlFor="invite_avatars" className="font-normal">
                    Show Avatars for Invites
                  </Label>
                  <span className="text-xs text-muted-foreground">
                    Display the avatars of the room and the inviter
                  </span>
                </div>
                <Switch id="invite_avatars" defaultChecked={inviteAvatars} />
              </div>
            </CardContent>
          </Card>
        </div>
      </ScrollArea>
    </div>
  )
}
