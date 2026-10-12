# frozen_string_literal: true

# /matrix/settings/notifications — Notifications
#
# Fractal: account_settings/mod + notifications_page.blp
#
# NOT IMPLEMENTED.
#
# Push rules: the global setting (All | DirectAndMentions | MentionsOnly),
# keywords, and the per-room overrides in matrix_rooms.notification_mode.
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
# account_settings/notifications_page.blp
#
#   <Adw.PreferencesPage id="NotificationsPage">
#     <Adw.PreferencesGroup>
#       <SwitchLoadingRow id="account_row" />
#       <Adw.SwitchRow id="session_row" />
#     </Adw.PreferencesGroup>
#     <Adw.PreferencesGroup id="global">
#       <CheckLoadingRow id="global_all_row" />
#       <CheckLoadingRow id="global_direct_row" />
#       <CheckLoadingRow id="global_mentions_row" />
#     </Adw.PreferencesGroup>
#     <Adw.PreferencesGroup>
#       <ListBox id="keywords" />
#     </Adw.PreferencesGroup>
#   </Adw.PreferencesPage>
#   <EntryAddRow id="keywords_add_row" />
#
# ── Build with ─────────────────────────────────────────────────────────────
#
# @reui/settings-12 — "Notification settings page with per-channel delivery modes and
#   collapsible auto-follow toggles". Per-channel delivery modes are
#   NotificationsGlobalSetting; the collapsible section holds the per-room overrides.
#
#   NotificationsGlobalSetting (3)  ->  ui/radio-group
#   NotificationsRoomSetting (4)    ->  ui/select per room row
#   keywords_list                   ->  ui/badge chips + ui/input-group to add
#   per_room_settings map           ->  ui/collapsible holding ui/item rows
#   account/session enabled         ->  ui/switch
#
# INSTALL, plain shadcn: radio-group, collapsible
#
# Push rules. The global setting and keywords are m.push_rules; the per-room
# overrides are the cached notification_mode on each room.
get "/" do
  rules = matrix_account_data("m.push_rules")

  keywords = Array(rules.dig("global", "content"))
    .select { |rule| rule["enabled"] != false && rule["rule_id"] !~ /\A\./ }
    .map { |rule| rule["pattern"] }
    .compact

  overrides = Models::Matrix::Room
    .exclude(notification_mode: nil)
    .all
    .map { |room| { roomId: room[:room_id], title: matrix_room_title(room), mode: room[:notification_mode] } }

  render(
    "matrix/settings/notifications",
    global:    "all",
    keywords:  keywords,
    overrides: overrides,
  )
end

post "/" do
  halt(501, "matrix: not implemented\n")
end

__END__

import { Form, Head, Link } from "@inertiajs/react"
import { ArrowLeft, Plus, X } from "lucide-react"

import { Badge } from "@/components/reui/badge"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Collapsible, CollapsibleContent, CollapsibleTrigger } from "@/components/ui/collapsible"
import {
  InputGroup,
  InputGroupAddon,
  InputGroupButton,
  InputGroupInput,
} from "@/components/ui/input-group"
import { Label } from "@/components/ui/label"
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group"
import { ScrollArea } from "@/components/ui/scroll-area"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import { ShellHeader } from "@/components/admin/slots"

// NotificationsGlobalSetting, Fractal's three.
const GLOBAL = [
  { value: "all", label: "All messages", hint: "Every message in every room." },
  { value: "direct", label: "Direct chats and mentions", hint: "Quiet in group rooms." },
  { value: "mentions", label: "Mentions and keywords only", hint: "Nothing else gets through." },
]

// NotificationsRoomSetting, Fractal's four.
const ROOM_MODES = [
  { value: "global", label: "Default" },
  { value: "all", label: "All messages" },
  { value: "mentions", label: "Mentions only" },
  { value: "mute", label: "Muted" },
]

export default function MatrixSettingsNotifications({
  global,
  keywords,
  overrides,
}: {
  global: string
  keywords: string[]
  overrides: { roomId: string; title: string; mode: string }[]
}) {
  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title="Notifications · matrix" />

      <ShellHeader>
        <Link href="/matrix/settings" className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="text-sm font-medium">Notifications</h1>
      </ShellHeader>

      <ScrollArea className="min-h-0 flex-1">
        <div className="mx-auto flex w-full max-w-2xl flex-col gap-4 p-6">
          <Card>
            <CardHeader>
              <CardTitle className="text-sm">What to notify about</CardTitle>
              <CardDescription>The default for every room without its own setting.</CardDescription>
            </CardHeader>
            <CardContent>
              <RadioGroup defaultValue={global} className="gap-3">
                {GLOBAL.map((option) => (
                  <div key={option.value} className="flex items-start gap-3">
                    <RadioGroupItem value={option.value} id={`g-${option.value}`} className="mt-0.5" />
                    <div className="flex flex-col gap-0.5">
                      <Label htmlFor={`g-${option.value}`} className="font-normal">
                        {option.label}
                      </Label>
                      <span className="text-xs text-muted-foreground">{option.hint}</span>
                    </div>
                  </div>
                ))}
              </RadioGroup>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Keywords</CardTitle>
              <CardDescription>
                A message containing one of these notifies you the way a mention does.
              </CardDescription>
            </CardHeader>
            <CardContent className="flex flex-col gap-3">
              {keywords.length > 0 && (
                <div className="flex flex-wrap gap-1.5">
                  {keywords.map((keyword) => (
                    <Badge key={keyword} variant="secondary" className="gap-1">
                      {keyword}
                      <button type="button" aria-label={`Remove ${keyword}`}>
                        <X className="size-3" />
                      </button>
                    </Badge>
                  ))}
                </div>
              )}
              <Form action="/matrix/settings/notifications" method="post">
                <InputGroup>
                  <InputGroupInput name="keyword" placeholder="Add a keyword" />
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

          <Collapsible defaultOpen={overrides.length > 0}>
            <Card>
              <CollapsibleTrigger className="w-full text-left">
                <CardHeader>
                  <CardTitle className="text-sm">
                    Per-room overrides
                    {overrides.length > 0 && (
                      <Badge variant="secondary" size="sm" className="ml-2">
                        {overrides.length}
                      </Badge>
                    )}
                  </CardTitle>
                  <CardDescription>Rooms set to something other than the default.</CardDescription>
                </CardHeader>
              </CollapsibleTrigger>
              <CollapsibleContent>
                <CardContent className="flex flex-col gap-1">
                  {overrides.length === 0 ? (
                    <p className="py-2 text-sm text-muted-foreground">
                      Every room is on the default.
                    </p>
                  ) : (
                    overrides.map((room) => (
                      <div key={room.roomId} className="flex items-center justify-between gap-3 py-1">
                        <Link
                          href={`/matrix/rooms/${encodeURIComponent(room.roomId)}`}
                          className="truncate text-sm hover:underline"
                        >
                          {room.title}
                        </Link>
                        <Select defaultValue={room.mode}>
                          <SelectTrigger size="sm" className="w-40 shrink-0">
                            <SelectValue />
                          </SelectTrigger>
                          <SelectContent>
                            {ROOM_MODES.map((mode) => (
                              <SelectItem key={mode.value} value={mode.value}>
                                {mode.label}
                              </SelectItem>
                            ))}
                          </SelectContent>
                        </Select>
                      </div>
                    ))
                  )}
                </CardContent>
              </CollapsibleContent>
            </Card>
          </Collapsible>
        </div>
      </ScrollArea>
    </div>
  )
}
