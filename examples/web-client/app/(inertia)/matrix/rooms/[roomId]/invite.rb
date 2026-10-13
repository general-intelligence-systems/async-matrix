# frozen_string_literal: true


get "/" do
  room = Models::Matrix::Room.first(room_id: params["roomId"]) || halt(404, "matrix: no such room\n")

  render(
    "matrix/rooms/[roomId]/invite",
    roomId:    room.room_id,
    roomTitle: room.title,
    existing:  room.members.exclude(membership: %w[leave ban]).select_map(:member_id),
  )
end

post "/" do
  halt(501, "matrix: not implemented\n")
end

__END__

import { Form, Head, Link } from "@inertiajs/react"
import { useState } from "react"
import { ArrowLeft, Plus, X } from "lucide-react"

import { Badge } from "@/components/reui/badge"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import {
  InputGroup,
  InputGroupAddon,
  InputGroupButton,
  InputGroupInput,
} from "@/components/ui/input-group"
import { ScrollArea } from "@/components/ui/scroll-area"
import { ShellHeader } from "@/components/admin/slots"

export default function MatrixRoomInvite({
  roomId,
  roomTitle,
  existing,
}: {
  roomId: string
  roomTitle: string
  existing: string[]
}) {
  const encoded = encodeURIComponent(roomId)
  const [draft, setDraft] = useState("")
  const [invitees, setInvitees] = useState<string[]>([])

  const add = () => {
    const id = draft.trim()
    // A Matrix id is @localpart:server. Anything else is a typo, and inviting
    // a typo silently does nothing on the server.
    if (!/^@[^:]+:.+/.test(id) || invitees.includes(id) || existing.includes(id)) return
    setInvitees([...invitees, id])
    setDraft("")
  }

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title={`Invite · ${roomTitle}`} />

      <ShellHeader>
        <Link href={`/matrix/rooms/${encoded}/members`} className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">Invite to {roomTitle}</h1>
      </ShellHeader>

      <ScrollArea className="min-h-0 flex-1">
        <div className="mx-auto flex w-full max-w-2xl flex-col gap-4 p-6">
          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Who to invite</CardTitle>
              <CardDescription>Full Matrix IDs, like @alice:example.org.</CardDescription>
            </CardHeader>
            <CardContent className="flex flex-col gap-3">
              <InputGroup>
                <InputGroupAddon>@</InputGroupAddon>
                <InputGroupInput
                  value={draft}
                  onChange={(event) => setDraft(event.target.value)}
                  onKeyDown={(event) => {
                    if (event.key === "Enter") {
                      event.preventDefault()
                      add()
                    }
                  }}
                  placeholder="alice:example.org"
                />
                <InputGroupAddon align="inline-end">
                  <InputGroupButton size="xs" onClick={add} type="button">
                    <Plus className="size-3.5" />
                    Add
                  </InputGroupButton>
                </InputGroupAddon>
              </InputGroup>

              {invitees.length > 0 && (
                <div className="flex flex-wrap gap-1.5">
                  {invitees.map((id) => (
                    <Badge key={id} variant="secondary" className="gap-1">
                      <span className="font-mono">{id}</span>
                      <button
                        type="button"
                        onClick={() => setInvitees(invitees.filter((other) => other !== id))}
                        aria-label={`Remove ${id}`}
                      >
                        <X className="size-3" />
                      </button>
                    </Badge>
                  ))}
                </div>
              )}

              <Form action={`/matrix/rooms/${encoded}/invite`} method="post">
                {invitees.map((id) => (
                  <input key={id} type="hidden" name="invitees[]" value={id} />
                ))}
                <Button type="submit" disabled={invitees.length === 0}>
                  Invite {invitees.length > 0 && invitees.length}
                </Button>
              </Form>

              {/* Invites fail one at a time -- a blocked user or a dead server
                  fails alone -- so the result has to be reported per person. */}
              <p className="text-xs text-muted-foreground">
                Each invite is sent separately and can fail on its own.
              </p>
            </CardContent>
          </Card>
        </div>
      </ScrollArea>
    </div>
  )
}
