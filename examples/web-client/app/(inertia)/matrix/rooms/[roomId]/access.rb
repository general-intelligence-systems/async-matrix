# frozen_string_literal: true


get "/" do
  room = Models::Matrix::Room.first(room_id: params["roomId"]) || halt(404, "matrix: no such room\n")

  render(
    "matrix/rooms/[roomId]/access",
    roomId:    room.room_id,
    roomTitle: room.title,
    joinRule:  room.join_rule || "invite",
    allow:     room.join_rule_allow.map{|entry| entry["room_id"]}.compact,
    history:   room.history_visibility || "shared",
    guests:    room.guest_access == "can_join",
  )
end

post "/" do
  halt(501, "matrix: not implemented\n")
end

__END__

import { Form, Head, Link } from "@inertiajs/react"
import { ArrowLeft } from "lucide-react"

import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Label } from "@/components/ui/label"
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group"
import { ScrollArea } from "@/components/ui/scroll-area"
import { Switch } from "@/components/ui/switch"
import { ShellHeader } from "@/components/admin/slots"

// The spec's five join rules. knock_restricted is omitted: it needs a space
// list to mean anything and the UI for that belongs with `restricted`.
const JOIN_RULES = [
  { value: "public", label: "Anyone", hint: "Anybody who finds the room can join." },
  { value: "knock", label: "Ask to join", hint: "People request access and a moderator decides." },
  { value: "restricted", label: "Space members", hint: "Members of a chosen space can join." },
  { value: "invite", label: "Invite only", hint: "Only people invited can join." },
]

const HISTORY = [
  { value: "world_readable", label: "Anyone", hint: "Even people who never joined." },
  { value: "shared", label: "Members", hint: "Everything, to anyone who joins." },
  { value: "invited", label: "From their invite", hint: "Only after they were invited." },
  { value: "joined", label: "From when they joined", hint: "Nothing from before." },
]

function Choice({
  name,
  options,
  value,
}: {
  name: string
  options: { value: string; label: string; hint: string }[]
  value: string
}) {
  return (
    <RadioGroup name={name} defaultValue={value} className="gap-3">
      {options.map((option) => (
        <div key={option.value} className="flex items-start gap-3">
          <RadioGroupItem value={option.value} id={`${name}-${option.value}`} className="mt-0.5" />
          <div className="flex flex-col gap-0.5">
            <Label htmlFor={`${name}-${option.value}`} className="font-normal">
              {option.label}
            </Label>
            <span className="text-xs text-muted-foreground">{option.hint}</span>
          </div>
        </div>
      ))}
    </RadioGroup>
  )
}

export default function MatrixRoomAccess({
  roomId,
  roomTitle,
  joinRule,
  allow,
  history,
  guests,
}: {
  roomId: string
  roomTitle: string
  joinRule: string
  allow: string[]
  history: string
  guests: boolean
}) {
  const encoded = encodeURIComponent(roomId)

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title={`Access · ${roomTitle}`} />

      <ShellHeader>
        <Link href={`/matrix/rooms/${encoded}/about`} className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">Access</h1>
      </ShellHeader>

      <ScrollArea className="min-h-0 flex-1">
        <Form
          action={`/matrix/rooms/${encoded}/access`}
          method="post"
          className="mx-auto flex w-full max-w-2xl flex-col gap-4 p-6"
        >
          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Who can join</CardTitle>
              <CardDescription>m.room.join_rules</CardDescription>
            </CardHeader>
            <CardContent className="flex flex-col gap-4">
              <Choice name="join_rule" options={JOIN_RULES} value={joinRule} />
              {allow.length > 0 && (
                <div className="rounded-md border p-3">
                  <p className="mb-2 text-xs font-medium text-muted-foreground">
                    Members of these spaces can join
                  </p>
                  <ul className="flex flex-col gap-1">
                    {allow.map((space) => (
                      <li key={space} className="truncate font-mono text-xs">
                        {space}
                      </li>
                    ))}
                  </ul>
                </div>
              )}
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Who can read history</CardTitle>
              <CardDescription>m.room.history_visibility</CardDescription>
            </CardHeader>
            <CardContent>
              <Choice name="history_visibility" options={HISTORY} value={history} />
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Guests</CardTitle>
              <CardDescription>m.room.guest_access</CardDescription>
            </CardHeader>
            <CardContent className="flex items-center justify-between gap-4">
              <Label htmlFor="guest_access" className="font-normal">
                Allow guest accounts to join
              </Label>
              <Switch id="guest_access" name="guest_access" defaultChecked={guests} />
            </CardContent>
          </Card>

          <Button type="submit" className="self-start">
            Save
          </Button>
        </Form>
      </ScrollArea>
    </div>
  )
}
