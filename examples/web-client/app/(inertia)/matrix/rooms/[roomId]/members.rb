# frozen_string_literal: true


MEMBERSHIPS = %w[join invite ban knock].freeze

get "/" do
  room = Models::Matrix::Room.first(room_id: params["roomId"]) || halt(404, "matrix: no such room\n")

  if MEMBERSHIPS.include?(params["membership"])
    membership = params["membership"]
  else
    membership = "join"
  end

  render(
    "matrix/rooms/[roomId]/members",
    roomId:     room.room_id,
    roomTitle:  room.title,
    membership: membership,
    members:    room.members.where(membership: membership).order(:member_id).all.map do |member|
      {
        memberId:    member.member_id,
        displayName: member.name,
        avatarUrl:   member.avatar_url,
        membership:  member.membership,
        powerLevel:  member.power_level,
        role:        member.role,
      }
    end,
    counts:     MEMBERSHIPS.to_h{|kind| [kind, room.members.where(membership: kind).count]},
  )
end

__END__

import { Head, Link, router } from "@inertiajs/react"
import { ArrowLeft, UserPlus } from "lucide-react"

import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Badge } from "@/components/reui/badge"
import { Button } from "@/components/ui/button"
import { Empty, EmptyDescription, EmptyHeader, EmptyTitle } from "@/components/ui/empty"
import { Item, ItemContent, ItemDescription, ItemMedia, ItemTitle } from "@/components/ui/item"
import { ScrollArea } from "@/components/ui/scroll-area"
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { ShellHeader } from "@/components/admin/slots"

type Member = {
  memberId: string
  displayName: string
  avatarUrl: string | null
  membership: string
  powerLevel: number
  role: string
}

const TABS = [
  { value: "join", label: "Joined" },
  { value: "invite", label: "Invited" },
  { value: "knock", label: "Requested" },
  { value: "ban", label: "Banned" },
]

const initial = (name: string) => name.replace(/^[#!@]/, "").charAt(0).toUpperCase()

export default function MatrixRoomMembers({
  roomId,
  roomTitle,
  membership,
  members,
  counts,
}: {
  roomId: string
  roomTitle: string
  membership: string
  members: Member[]
  counts: Record<string, number>
}) {
  const encoded = encodeURIComponent(roomId)

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title={`Members · ${roomTitle}`} />

      <ShellHeader>
        <Link
          href={`/matrix/rooms/${encoded}`}
          className="text-muted-foreground hover:text-foreground"
        >
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">Members</h1>
        <Button size="sm" className="ms-auto" nativeButton={false} render={<Link href={`/matrix/rooms/${encoded}/invite`} />}>
            <UserPlus className="size-4" />
            Invite
          </Button>
      </ShellHeader>

      <div className="border-b px-4 py-2">
        {/* Membership is a query param, not client state: a filtered member
            list is a link somebody can send. */}
        <Tabs
          value={membership}
          onValueChange={(value) =>
            router.get(`/matrix/rooms/${encoded}/members`, { membership: value }, { preserveState: false })
          }
        >
          <TabsList>
            {TABS.map((tab) => (
              <TabsTrigger key={tab.value} value={tab.value}>
                {tab.label}
                {counts[tab.value] > 0 && (
                  <Badge variant="secondary" size="sm" className="ml-1.5">
                    {counts[tab.value]}
                  </Badge>
                )}
              </TabsTrigger>
            ))}
          </TabsList>
        </Tabs>
      </div>

      <ScrollArea className="min-h-0 flex-1">
        <div className="mx-auto w-full max-w-3xl p-4">
          {members.length === 0 ? (
            <Empty className="py-12">
              <EmptyHeader>
                <EmptyTitle>Nobody here</EmptyTitle>
                <EmptyDescription>No members with this membership.</EmptyDescription>
              </EmptyHeader>
            </Empty>
          ) : (
            <div className="flex flex-col gap-1">
              {members.map((member) => (
                <Item key={member.memberId} render={<Link href={`/matrix/users/${encodeURIComponent(member.memberId)}`} />}>
                    <ItemMedia>
                      <Avatar className="size-8">
                        {member.avatarUrl && <AvatarImage src={member.avatarUrl} alt="" />}
                        <AvatarFallback className="text-[11px]">
                          {initial(member.displayName)}
                        </AvatarFallback>
                      </Avatar>
                    </ItemMedia>
                    <ItemContent>
                      <ItemTitle>{member.displayName}</ItemTitle>
                      <ItemDescription>{member.memberId}</ItemDescription>
                    </ItemContent>
                    {member.role !== "Default" && (
                      <Badge variant={member.role === "Admin" ? "primary" : "secondary"} size="sm">
                        {member.role}
                      </Badge>
                    )}
                  </Item>
              ))}
            </div>
          )}
        </div>
      </ScrollArea>
    </div>
  )
}
