# frozen_string_literal: true


ACTIONS = [
  ["invite",              "Invite people",           0],
  ["kick",                "Remove people",           50],
  ["ban",                 "Ban people",              50],
  ["redact",              "Delete others' messages", 50],
  ["events_default",      "Send messages",           0],
  ["state_default",       "Change settings",         50],
  ["m.room.name",         "Change the name",         nil],
  ["m.room.topic",        "Change the topic",        nil],
  ["m.room.avatar",       "Change the avatar",       nil],
  ["m.room.power_levels", "Change permissions",      nil],
  ["m.room.tombstone",    "Upgrade the room",        100],
].freeze

ACTIONS = [
  ["invite",              "Invite people",           0],
  ["kick",                "Remove people",           50],
  ["ban",                 "Ban people",              50],
  ["redact",              "Delete others' messages", 50],
  ["events_default",      "Send messages",           0],
  ["state_default",       "Change settings",         50],
  ["m.room.name",         "Change the name",         nil],
  ["m.room.topic",        "Change the topic",        nil],
  ["m.room.avatar",       "Change the avatar",       nil],
  ["m.room.power_levels", "Change permissions",      nil],
  ["m.room.tombstone",    "Upgrade the room",        100],
].freeze

get "/" do
  room = Models::Matrix::Room.first(room_id: params["roomId"]) || halt(404, "matrix: no such room\n")
  levels = room.power_levels
  state_default = (levels["state_default"] || 50).to_i

  render(
    "matrix/rooms/[roomId]/permissions",
    roomId:     room.room_id,
    roomTitle:  room.title,
    actions:    ACTIONS.map do |key, label, default|
      if default.nil?
        level = levels.dig("events", key) || state_default
      else
        level = levels[key] || default
      end

      { key: key, label: label, level: level.to_i }
    end,
    default:    (levels["users_default"] || 0).to_i,
    privileged: (levels["users"] || {}).sort_by{|_id, level| -level.to_i}.map do |member_id, level|
      {
        memberId: member_id,
        level:    level.to_i,
        role:     Models::Matrix::RoomMember::ROLES.fetch(level.to_i, "Custom"),
        creator:  member_id == room.creator,
      }
    end,
  )
end

post "/" do
  halt(501, "matrix: not implemented\n")
end

__END__

import { Head, Link } from "@inertiajs/react"
import { ArrowLeft, Lock } from "lucide-react"

import { Badge } from "@/components/reui/badge"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { ScrollArea } from "@/components/ui/scroll-area"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { ShellHeader } from "@/components/admin/slots"

type Action = { key: string; label: string; level: number }
type Privileged = { memberId: string; level: number; role: string; creator: boolean }

// The three named rungs. Anything else is Custom and shows its number.
const RUNGS = [
  { value: "0", label: "Default" },
  { value: "50", label: "Moderator" },
  { value: "100", label: "Admin" },
]

const rungFor = (level: number) =>
  RUNGS.find((rung) => Number(rung.value) === level)?.value ?? "custom"

export default function MatrixRoomPermissions({
  roomId,
  roomTitle,
  actions,
  default: usersDefault,
  privileged,
}: {
  roomId: string
  roomTitle: string
  actions: Action[]
  default: number
  privileged: Privileged[]
}) {
  const encoded = encodeURIComponent(roomId)

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title={`Permissions · ${roomTitle}`} />

      <ShellHeader>
        <Link href={`/matrix/rooms/${encoded}/about`} className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">Permissions</h1>
      </ShellHeader>

      <ScrollArea className="min-h-0 flex-1">
        <div className="mx-auto flex w-full max-w-3xl flex-col gap-4 p-6">
          <Card>
            <CardHeader>
              <CardTitle className="text-sm">What each level may do</CardTitle>
              <CardDescription>
                The level a member needs before the action is allowed. Everyone starts at{" "}
                {usersDefault}.
              </CardDescription>
            </CardHeader>
            <CardContent>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Action</TableHead>
                    <TableHead className="w-44">Required level</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {actions.map((action) => {
                    const rung = rungFor(action.level)
                    return (
                      <TableRow key={action.key}>
                        <TableCell>
                          <span>{action.label}</span>
                          <code className="ml-2 font-mono text-xs text-muted-foreground">
                            {action.key}
                          </code>
                        </TableCell>
                        <TableCell>
                          <Select defaultValue={rung}>
                            <SelectTrigger size="sm">
                              <SelectValue />
                            </SelectTrigger>
                            <SelectContent>
                              {RUNGS.map((option) => (
                                <SelectItem key={option.value} value={option.value}>
                                  {option.label}
                                </SelectItem>
                              ))}
                              {rung === "custom" && (
                                <SelectItem value="custom">Custom ({action.level})</SelectItem>
                              )}
                            </SelectContent>
                          </Select>
                        </TableCell>
                      </TableRow>
                    )
                  })}
                </TableBody>
              </Table>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Members with a level set</CardTitle>
              <CardDescription>
                Everyone else is at the default. The room creator cannot be demoted.
              </CardDescription>
            </CardHeader>
            <CardContent className="flex flex-col gap-1">
              {privileged.length === 0 ? (
                <p className="py-4 text-sm text-muted-foreground">
                  Nobody has been given a level above the default.
                </p>
              ) : (
                privileged.map((member) => (
                  <div
                    key={member.memberId}
                    className="flex items-center justify-between gap-3 rounded-md px-2 py-1.5 hover:bg-accent/50"
                  >
                    <Link
                      href={`/matrix/users/${encodeURIComponent(member.memberId)}`}
                      className="truncate font-mono text-sm hover:underline"
                    >
                      {member.memberId}
                    </Link>
                    <div className="flex shrink-0 items-center gap-2">
                      <Badge variant={member.level >= 100 ? "primary" : "secondary"} size="sm">
                        {member.role} · {member.level}
                      </Badge>
                      {member.creator && (
                        <Lock className="size-3 text-muted-foreground" aria-label="Room creator" />
                      )}
                    </div>
                  </div>
                ))
              )}
              <Button variant="outline" size="sm" className="mt-2 self-start">
                Add member
              </Button>
            </CardContent>
          </Card>
        </div>
      </ScrollArea>
    </div>
  )
}
