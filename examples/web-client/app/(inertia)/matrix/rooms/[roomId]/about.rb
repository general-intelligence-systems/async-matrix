# frozen_string_literal: true


get "/" do
  room = Models::Matrix::Room.first(room_id: params["roomId"]) || halt(404, "matrix: no such room\n")
  me = Models::Matrix::Credential.first&.matrix_user_id.to_s

  render(
    "matrix/rooms/[roomId]/about",
    room: {
      roomId:         room.room_id,
      title:          room.title,
      avatarUrl:      room.avatar_url,
      topic:          room.topic,
      canonicalAlias: room.canonical_alias,
      encrypted:      room.encrypted,
      direct:         room.direct,
      memberCount:    room.joined_member_count.to_i,
      version:        room.room_version,
      createdBy:      room.creator,
      predecessor:    room.predecessor_room_id,
      successor:      room.successor_room_id,
      tombstoned:     room.tombstoned,
    },
    can:  {
      name:   room.can_send_state?("m.room.name", me),
      topic:  room.can_send_state?("m.room.topic", me),
      avatar: room.can_send_state?("m.room.avatar", me),
    },
  )
end

post "/" do
  halt(501, "matrix: not implemented\n")
end

__END__

import { Form, Head, Link } from "@inertiajs/react"
import { ArrowLeft, Hash, Lock, Users } from "lucide-react"

import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Alert, AlertDescription, AlertTitle } from "@/components/reui/alert"
import { Badge } from "@/components/reui/badge"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Item, ItemContent, ItemDescription, ItemTitle } from "@/components/ui/item"
import { Label } from "@/components/ui/label"
import { ScrollArea } from "@/components/ui/scroll-area"
import { Textarea } from "@/components/ui/textarea"
import { ShellHeader } from "@/components/admin/slots"

type Room = {
  roomId: string
  title: string
  avatarUrl: string | null
  topic: string | null
  canonicalAlias: string | null
  encrypted: boolean
  direct: boolean
  memberCount: number
  version: string | null
  createdBy: string | null
  predecessor: string | null
  successor: string | null
  tombstoned: boolean
}

const initial = (name: string) => name.replace(/^[#!@]/, "").charAt(0).toUpperCase()

export default function MatrixRoomAbout({
  room,
  can,
}: {
  room: Room
  can: { name: boolean; topic: boolean; avatar: boolean }
}) {
  const encoded = encodeURIComponent(room.roomId)
  const readOnly = !can.name && !can.topic

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title={`About · ${room.title}`} />

      <ShellHeader>
        <Link href={`/matrix/rooms/${encoded}`} className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">Room details</h1>
      </ShellHeader>

      <ScrollArea className="min-h-0 flex-1">
        <div className="mx-auto flex w-full max-w-2xl flex-col gap-4 p-6">
          {room.tombstoned && (
            <Alert variant="warning">
              <AlertTitle>This room has been upgraded</AlertTitle>
              <AlertDescription>
                A newer version replaced it. New messages belong in the successor.
              </AlertDescription>
            </Alert>
          )}

          <div className="flex flex-col items-center gap-3 py-2">
            <Avatar className="size-20">
              {room.avatarUrl && <AvatarImage src={room.avatarUrl} alt="" />}
              <AvatarFallback className="text-2xl">{initial(room.title)}</AvatarFallback>
            </Avatar>
            <div className="flex items-center gap-2">
              <h2 className="text-lg font-semibold">{room.title}</h2>
              {room.encrypted && <Lock className="size-4 text-muted-foreground" />}
            </div>
            {room.canonicalAlias && (
              <span className="text-sm text-muted-foreground">{room.canonicalAlias}</span>
            )}
          </div>

          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Details</CardTitle>
            </CardHeader>
            <CardContent>
              <Form action={`/matrix/rooms/${encoded}/about`} method="post" className="flex flex-col gap-4">
                <div className="flex flex-col gap-2">
                  <Label htmlFor="name">Name</Label>
                  <Input id="name" name="name" defaultValue={room.title} disabled={!can.name} />
                </div>
                <div className="flex flex-col gap-2">
                  <Label htmlFor="topic">Topic</Label>
                  <Textarea
                    id="topic"
                    name="topic"
                    rows={3}
                    defaultValue={room.topic ?? ""}
                    disabled={!can.topic}
                  />
                </div>
                {readOnly ? (
                  <p className="text-xs text-muted-foreground">
                    You do not have permission to change these.
                  </p>
                ) : (
                  <Button type="submit" className="self-start">
                    Save
                  </Button>
                )}
              </Form>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Room</CardTitle>
            </CardHeader>
            <CardContent className="flex flex-col gap-1">
              <Item render={<Link href={`/matrix/rooms/${encoded}/members`} />}>
                  <ItemContent>
                    <ItemTitle>Members</ItemTitle>
                    <ItemDescription>{room.memberCount} joined</ItemDescription>
                  </ItemContent>
                  <Users className="size-4 text-muted-foreground" />
                </Item>
              <Item render={<Link href={`/matrix/rooms/${encoded}/addresses`} />}>
                  <ItemContent>
                    <ItemTitle>Addresses</ItemTitle>
                    <ItemDescription>{room.canonicalAlias ?? "No published address"}</ItemDescription>
                  </ItemContent>
                  <Hash className="size-4 text-muted-foreground" />
                </Item>
              <Item render={<Link href={`/matrix/rooms/${encoded}/access`} />}>
                  <ItemContent>
                    <ItemTitle>Access</ItemTitle>
                    <ItemDescription>Who can join and read history</ItemDescription>
                  </ItemContent>
                </Item>
              <Item render={<Link href={`/matrix/rooms/${encoded}/permissions`} />}>
                  <ItemContent>
                    <ItemTitle>Permissions</ItemTitle>
                    <ItemDescription>Power levels per action</ItemDescription>
                  </ItemContent>
                </Item>
              <Item render={<Link href={`/matrix/rooms/${encoded}/media`} />}>
                  <ItemContent>
                    <ItemTitle>Media</ItemTitle>
                    <ItemDescription>Files sent in this room</ItemDescription>
                  </ItemContent>
                </Item>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Advanced</CardTitle>
            </CardHeader>
            <CardContent className="flex flex-col gap-2 text-sm">
              <div className="flex items-center justify-between gap-4">
                <span className="text-muted-foreground">Internal ID</span>
                <code className="truncate font-mono text-xs">{room.roomId}</code>
              </div>
              <div className="flex items-center justify-between gap-4">
                <span className="text-muted-foreground">Version</span>
                <Badge variant="secondary" size="sm">{room.version ?? "unknown"}</Badge>
              </div>
              {room.createdBy && (
                <div className="flex items-center justify-between gap-4">
                  <span className="text-muted-foreground">Created by</span>
                  <code className="truncate font-mono text-xs">{room.createdBy}</code>
                </div>
              )}
              <Button variant="outline" size="sm" className="mt-2 self-start" nativeButton={false} render={<Link href={`/matrix/rooms/${encoded}/upgrade`} />}>Upgrade room</Button>
            </CardContent>
          </Card>
        </div>
      </ScrollArea>
    </div>
  )
}
