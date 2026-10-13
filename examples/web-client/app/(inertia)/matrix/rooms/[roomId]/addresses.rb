# frozen_string_literal: true


get "/" do
  room = Models::Matrix::Room.first(room_id: params["roomId"]) || halt(404, "matrix: no such room\n")

  render(
    "matrix/rooms/[roomId]/addresses",
    roomId:    room.room_id,
    roomTitle: room.title,
    canonical: room.canonical_alias,
    alt:       room.alt_aliases,
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
