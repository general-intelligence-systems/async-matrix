# frozen_string_literal: true


get "/" do
  credential = Models::Matrix::Credential.first
  state = Models::Matrix::DeviceState.first
  profile = Models::Matrix::GlobalProfile.first(matrix_user_id: credential&.matrix_user_id)

  render(
    "matrix/settings",
    account: {
      userId:      credential&.matrix_user_id,
      deviceId:    credential&.device_id,
      homeserver:  credential&.homeserver_url,
      displayName: profile&.display_name,
      avatarUrl:   profile&.avatar_url,
    },
    device:  {
      syncing:       !Models::Matrix::KV.sync_token.nil?,
      keysPublished: state&.keys_published || false,
      otkCount:      state&.otk_count.to_i,
    },
  )
end

post "/" do
  halt(501, "matrix: not implemented\n")
end

__END__

import { Form, Head, Link } from "@inertiajs/react"
import { CircleCheck, CircleX } from "lucide-react"

import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Alert, AlertDescription, AlertTitle } from "@/components/reui/alert"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Item, ItemContent, ItemDescription, ItemTitle } from "@/components/ui/item"
import { Label } from "@/components/ui/label"
import { ScrollArea } from "@/components/ui/scroll-area"
import { ShellHeader } from "@/components/admin/slots"

const SECTIONS = [
  { href: "/matrix/settings/notifications", title: "Notifications", hint: "Push rules and keywords" },
  { href: "/matrix/settings/encryption", title: "Encryption", hint: "Cross-signing, recovery and key backup" },
  { href: "/matrix/settings/safety", title: "Safety", hint: "Ignored users and media previews" },
  { href: "/matrix/settings/devices", title: "Devices", hint: "Where this account is signed in" },
]

export default function MatrixSettings({
  account,
  device,
}: {
  account: {
    userId: string | null
    deviceId: string | null
    homeserver: string | null
    displayName: string | null
    avatarUrl: string | null
  }
  device: { syncing: boolean; keysPublished: boolean; otkCount: number }
}) {
  const name = account.displayName ?? account.userId ?? "Not configured"

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title="Matrix settings" />

      <ShellHeader>
        <h1 className="text-sm font-medium">Settings</h1>
      </ShellHeader>

      <ScrollArea className="min-h-0 flex-1">
        <div className="mx-auto flex w-full max-w-2xl flex-col gap-4 p-6">
          {!account.userId && (
            <Alert variant="warning">
              <AlertTitle>No device configured</AlertTitle>
              <AlertDescription>
                There is no row in matrix_credentials, so this app is not signed in to a
                homeserver yet.
              </AlertDescription>
            </Alert>
          )}

          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Account</CardTitle>
            </CardHeader>
            <CardContent className="flex flex-col gap-4">
              <div className="flex items-center gap-3">
                <Avatar className="size-14">
                  {account.avatarUrl && <AvatarImage src={account.avatarUrl} alt="" />}
                  <AvatarFallback>{name.replace(/^@/, "").charAt(0).toUpperCase()}</AvatarFallback>
                </Avatar>
                <div className="flex min-w-0 flex-col">
                  <span className="truncate font-medium">{name}</span>
                  <code className="truncate font-mono text-xs text-muted-foreground">
                    {account.userId ?? "—"}
                  </code>
                </div>
              </div>

              <Form action="/matrix/settings" method="post" className="flex flex-col gap-3">
                <div className="flex flex-col gap-2">
                  <Label htmlFor="display_name">Display name</Label>
                  <Input
                    id="display_name"
                    name="display_name"
                    defaultValue={account.displayName ?? ""}
                  />
                </div>
                <Button type="submit" className="self-start" disabled={!account.userId}>
                  Save
                </Button>
              </Form>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-sm">This device</CardTitle>
              <CardDescription>
                The server-side device this app syncs and sends as.
              </CardDescription>
            </CardHeader>
            <CardContent className="flex flex-col gap-2 text-sm">
              <div className="flex items-center justify-between gap-4">
                <span className="text-muted-foreground">Homeserver</span>
                <code className="truncate font-mono text-xs">{account.homeserver ?? "—"}</code>
              </div>
              <div className="flex items-center justify-between gap-4">
                <span className="text-muted-foreground">Device ID</span>
                <code className="truncate font-mono text-xs">{account.deviceId ?? "—"}</code>
              </div>
              <div className="flex items-center justify-between gap-4">
                <span className="text-muted-foreground">Sync</span>
                <span className="flex items-center gap-1 text-xs">
                  {device.syncing ? (
                    <>
                      <CircleCheck className="size-3.5 text-primary" /> has a cursor
                    </>
                  ) : (
                    <>
                      <CircleX className="size-3.5 text-muted-foreground" /> never synced
                    </>
                  )}
                </span>
              </div>
              <div className="flex items-center justify-between gap-4">
                <span className="text-muted-foreground">One-time keys</span>
                {/* A device that runs out stops being reachable for new
                    sessions, silently -- so the number is worth surfacing. */}
                <span className="tabular-nums text-xs">{device.otkCount}</span>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-sm">More</CardTitle>
            </CardHeader>
            <CardContent className="flex flex-col gap-1">
              {SECTIONS.map((section) => (
                <Item key={section.href} render={<Link href={section.href} />}>
<ItemContent>
                      <ItemTitle>{section.title}</ItemTitle>
                      <ItemDescription>{section.hint}</ItemDescription>
                    </ItemContent>
                  </Item>
              ))}
            </CardContent>
          </Card>
        </div>
      </ScrollArea>
    </div>
  )
}
