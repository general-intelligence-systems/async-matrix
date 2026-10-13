# frozen_string_literal: true

get "/" do
  render(
    "matrix/explore",
    query:  params["q"].to_s,
    server: params["server"].to_s,
    joined: Models::Matrix::Room
      .where(membership: "join")
      .select_map(:room_id),
    results: [],
  )
end

__END__

import { Head, Link, router } from "@inertiajs/react"
import { useState } from "react"
import { Globe, Lock, Search, Users } from "lucide-react"

import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Badge } from "@/components/reui/badge"
import { Button } from "@/components/ui/button"
import { Empty, EmptyDescription, EmptyHeader, EmptyMedia, EmptyTitle } from "@/components/ui/empty"
import {
  InputGroup,
  InputGroupAddon,
  InputGroupInput,
} from "@/components/ui/input-group"
import { Item, ItemContent, ItemDescription, ItemMedia, ItemTitle } from "@/components/ui/item"
import { ScrollArea } from "@/components/ui/scroll-area"
import { ShellHeader } from "@/components/admin/slots"

type PublicRoom = {
  roomId: string
  name: string | null
  topic: string | null
  alias: string | null
  avatarUrl: string | null
  members: number
  worldReadable: boolean
  guestCanJoin: boolean
}

const initial = (name: string) => name.replace(/^[#!@]/, "").charAt(0).toUpperCase()

export default function MatrixExplore({
  query,
  server,
  joined,
  results,
}: {
  query: string
  server: string
  joined: string[]
  results: PublicRoom[]
}) {
  const [draft, setDraft] = useState(query)

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title="Explore · matrix" />

      <ShellHeader>
        <Globe className="size-4 text-muted-foreground" />
        <h1 className="text-sm font-medium">Explore</h1>
      </ShellHeader>

      <div className="border-b p-3">
        <div className="mx-auto flex w-full max-w-3xl gap-2">
          <InputGroup className="flex-1">
            <InputGroupAddon>
              <Search className="size-3.5" />
            </InputGroupAddon>
            <InputGroupInput
              value={draft}
              onChange={(event) => setDraft(event.target.value)}
              onKeyDown={(event) => {
                if (event.key === "Enter") {
                  router.get("/matrix/explore", { q: draft, server }, { preserveState: false })
                }
              }}
              placeholder="Search public rooms"
            />
          </InputGroup>
          {/* The server to ask. A directory is per-homeserver, so this is part
              of the query rather than a preference. */}
          <InputGroup className="w-56">
            <InputGroupAddon>Server</InputGroupAddon>
            <InputGroupInput
              defaultValue={server}
              placeholder="this server"
              onKeyDown={(event) => {
                if (event.key === "Enter") {
                  router.get(
                    "/matrix/explore",
                    { q: draft, server: event.currentTarget.value },
                    { preserveState: false }
                  )
                }
              }}
            />
          </InputGroup>
        </div>
      </div>

      <ScrollArea className="min-h-0 flex-1">
        <div className="mx-auto w-full max-w-3xl p-4">
          {results.length === 0 ? (
            <Empty className="py-12">
              <EmptyHeader>
                <EmptyMedia variant="icon">
                  <Globe />
                </EmptyMedia>
                <EmptyTitle>{query ? "No rooms found" : "Search the directory"}</EmptyTitle>
                <EmptyDescription>
                  {query
                    ? `Nothing published matches "${query}".`
                    : "Public rooms published by a homeserver appear here."}
                </EmptyDescription>
              </EmptyHeader>
            </Empty>
          ) : (
            <div className="flex flex-col gap-1">
              {results.map((room) => {
                const already = joined.includes(room.roomId)
                const title = room.name ?? room.alias ?? room.roomId

                return (
                  <Item key={room.roomId}>
                    <ItemMedia>
                      <Avatar className="size-9">
                        {room.avatarUrl && <AvatarImage src={room.avatarUrl} alt="" />}
                        <AvatarFallback>{initial(title)}</AvatarFallback>
                      </Avatar>
                    </ItemMedia>
                    <ItemContent>
                      <ItemTitle className="flex items-center gap-1.5">
                        {title}
                        {!room.worldReadable && (
                          <Lock className="size-3 text-muted-foreground" aria-label="History not public" />
                        )}
                      </ItemTitle>
                      <ItemDescription className="line-clamp-1">
                        {room.topic ?? room.alias ?? room.roomId}
                      </ItemDescription>
                    </ItemContent>
                    <div className="flex shrink-0 items-center gap-2">
                      <Badge variant="outline" size="sm">
                        <Users className="size-2.5" />
                        {room.members}
                      </Badge>
                      {already ? (
                        <Button size="sm" variant="outline" nativeButton={false} render={<Link href={`/matrix/rooms/${encodeURIComponent(room.roomId)}`} />}>Open</Button>
                      ) : (
                        <Button size="sm">Join</Button>
                      )}
                    </div>
                  </Item>
                )
              })}
            </div>
          )}
        </div>
      </ScrollArea>
    </div>
  )
}
