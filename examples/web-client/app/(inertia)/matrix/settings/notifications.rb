# frozen_string_literal: true


get "/" do
  rules = Models::Matrix::AccountData
    .content_for(event_type: Models::Matrix::AccountData::PUSH_RULES).to_h

  render(
    "matrix/settings/notifications",
    global:    "all",
    keywords:  Array(rules.dig("global", "content"))
      .reject{|rule| rule["enabled"] == false || rule["rule_id"].to_s.start_with?(".")}
      .filter_map{|rule| rule["pattern"]},
    overrides: Models::Matrix::Room
      .exclude(notification_mode: nil)
      .all
      .map{|room| { roomId: room.room_id, title: room.title, mode: room.notification_mode }},
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
