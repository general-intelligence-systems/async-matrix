# frozen_string_literal: true


get "/" do
  user_id = params["userId"].to_s
  profile = Models::Matrix::GlobalProfile.first(matrix_user_id: user_id)
  identity = Models::Matrix::UserIdentity.first(matrix_user_id: user_id)
  ignored = Models::Matrix::AccountData
    .content_for(event_type: Models::Matrix::AccountData::IGNORED_USERS).to_h

  shared = Models::Matrix::RoomMember.where(member_id: user_id, membership: "join")

  render(
    "matrix/users/[userId]",
    userId:   user_id,
    profile:  {
      displayName: profile&.display_name,
      avatarUrl:   profile&.avatar_url,
    },
    verified: identity&.verified || false,
    ignored:  ignored["ignored_users"].to_h.key?(user_id),
    devices:  Models::Matrix::Device.of_user(user_id).live.order(:device_id).all.map do |device|
      {
        deviceId:    device.device_id,
        displayName: device.display_name,
        identityKey: device.identity_key,
        fingerprint: device.fingerprint,
        trust:       device.trust_state,
      }
    end,
    rooms:    Models::Matrix::Room
      .where(room_id: shared.select_map(:room_id))
      .all
      .map{|room| { roomId: room.room_id, title: room.title }},
  )
end

post "/" do
  halt(501, "matrix: not implemented\n")
end

__END__

import { Head, Link } from "@inertiajs/react"
import { ArrowLeft, BadgeCheck, EyeOff, ShieldQuestion, Smartphone } from "lucide-react"

import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Badge } from "@/components/reui/badge"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Item, ItemContent, ItemDescription, ItemMedia, ItemTitle } from "@/components/ui/item"
import { Label } from "@/components/ui/label"
import { ScrollArea } from "@/components/ui/scroll-area"
import { Switch } from "@/components/ui/switch"
import { ShellHeader } from "@/components/admin/slots"

type Device = {
  deviceId: string
  displayName: string | null
  identityKey: string | null
  fingerprint: string | null
  trust: string
}

const initial = (name: string) => name.replace(/^[#!@]/, "").charAt(0).toUpperCase()

export default function MatrixUser({
  userId,
  profile,
  verified,
  ignored,
  devices,
  rooms,
}: {
  userId: string
  profile: { displayName: string | null; avatarUrl: string | null }
  verified: boolean
  ignored: boolean
  devices: Device[]
  rooms: { roomId: string; title: string }[]
}) {
  const name = profile.displayName ?? userId

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title={`${name} · matrix`} />

      <ShellHeader>
        <Link href="/matrix" className="text-muted-foreground hover:text-foreground" aria-label="Back">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">{name}</h1>
      </ShellHeader>

      <ScrollArea className="min-h-0 flex-1">
        <div className="mx-auto flex w-full max-w-2xl flex-col gap-4 p-6">
          <div className="flex flex-col items-center gap-3 py-2">
            <Avatar className="size-20">
              {profile.avatarUrl && <AvatarImage src={profile.avatarUrl} alt="" />}
              <AvatarFallback className="text-2xl">{initial(name)}</AvatarFallback>
            </Avatar>
            <div className="flex items-center gap-2">
              <h1 className="text-lg font-semibold">{name}</h1>
              {verified && (
                <Badge variant="primary" size="sm">
                  <BadgeCheck className="size-2.5" />
                  Verified
                </Badge>
              )}
            </div>
            <code className="font-mono text-sm text-muted-foreground">{userId}</code>
            <div className="flex gap-2">
              <Button size="sm">Message</Button>
              {!verified && (
                <Button size="sm" variant="outline">
                  Verify
                </Button>
              )}
            </div>
          </div>

          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Sessions</CardTitle>
              <CardDescription>
                {/* An unverified device is a device that can read this user's
                    messages without you having confirmed it is theirs. */}
                Devices signed in as this user. Encrypted messages reach every one of them.
              </CardDescription>
            </CardHeader>
            <CardContent className="flex flex-col gap-1">
              {devices.length === 0 ? (
                <p className="py-3 text-sm text-muted-foreground">
                  No device keys stored. They appear after a key query.
                </p>
              ) : (
                devices.map((device) => (
                  <Item key={device.deviceId}>
                    <ItemMedia variant="icon">
                      <Smartphone className="size-4" />
                    </ItemMedia>
                    <ItemContent>
                      <ItemTitle>{device.displayName ?? device.deviceId}</ItemTitle>
                      <ItemDescription className="font-mono">{device.deviceId}</ItemDescription>
                    </ItemContent>
                    <Badge
                      variant={device.trust === "verified" ? "primary" : "secondary"}
                      size="sm"
                    >
                      {device.trust === "verified" ? (
                        <BadgeCheck className="size-2.5" />
                      ) : (
                        <ShieldQuestion className="size-2.5" />
                      )}
                      {device.trust}
                    </Badge>
                  </Item>
                ))
              )}
            </CardContent>
          </Card>

          {rooms.length > 0 && (
            <Card>
              <CardHeader>
                <CardTitle className="text-sm">Rooms in common</CardTitle>
              </CardHeader>
              <CardContent className="flex flex-col gap-1">
                {rooms.map((room) => (
                  <Item key={room.roomId} render={<Link href={`/matrix/rooms/${encodeURIComponent(room.roomId)}`} />}>
                      <ItemContent>
                        <ItemTitle>{room.title}</ItemTitle>
                      </ItemContent>
                    </Item>
                ))}
              </CardContent>
            </Card>
          )}

          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Safety</CardTitle>
            </CardHeader>
            <CardContent className="flex items-center justify-between gap-4">
              <div className="flex flex-col gap-0.5">
                <Label htmlFor="ignored" className="font-normal">
                  <EyeOff className="mr-1.5 inline size-3.5" />
                  Ignore this user
                </Label>
                <span className="text-xs text-muted-foreground">
                  Hides their messages everywhere, and their invites with them.
                </span>
              </div>
              <Switch id="ignored" defaultChecked={ignored} />
            </CardContent>
          </Card>
        </div>
      </ScrollArea>
    </div>
  )
}
