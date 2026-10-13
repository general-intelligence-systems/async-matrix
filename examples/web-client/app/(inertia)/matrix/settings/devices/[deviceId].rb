# frozen_string_literal: true


get "/" do
  credential = Models::Matrix::Credential.first
  device = Models::Matrix::Device.first(
    matrix_user_id: credential&.matrix_user_id, device_id: params["deviceId"].to_s,
  ) || halt(404, "matrix: no such device\n")

  render(
    "matrix/settings/devices/[deviceId]",
    current: credential.device_id == device.device_id,
    device:  {
      deviceId:    device.device_id,
      displayName: device.display_name,
      identityKey: device.identity_key,
      fingerprint: device.fingerprint,
      trust:       device.trust_state,
      firstSeen:   device.first_seen_at,
    },
  )
end

post "/" do
  halt(501, "matrix: not implemented\n")
end

__END__

import { Form, Head, Link } from "@inertiajs/react"
import { ArrowLeft, BadgeCheck, ShieldQuestion } from "lucide-react"

import { Badge } from "@/components/reui/badge"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { ScrollArea } from "@/components/ui/scroll-area"
import { ShellHeader } from "@/components/admin/slots"

export default function MatrixSettingsDevice({
  current,
  device,
}: {
  current: boolean
  device: {
    deviceId: string
    displayName: string | null
    identityKey: string | null
    fingerprint: string | null
    trust: string
    firstSeen: number | null
  }
}) {
  const encoded = encodeURIComponent(device.deviceId)
  const verified = device.trust === "verified"

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title={`${device.displayName ?? device.deviceId} · matrix`} />

      <ShellHeader>
        <Link href="/matrix/settings/devices" className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">
          {device.displayName ?? device.deviceId}
        </h1>
        <Badge variant={verified ? "primary" : "secondary"} size="sm" className="ms-auto">
          {verified ? <BadgeCheck className="size-2.5" /> : <ShieldQuestion className="size-2.5" />}
          {device.trust}
        </Badge>
      </ShellHeader>

      <ScrollArea className="min-h-0 flex-1">
        <div className="mx-auto flex w-full max-w-2xl flex-col gap-4 p-6">
          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Name</CardTitle>
              <CardDescription>Everyone you share a room with can see this.</CardDescription>
            </CardHeader>
            <CardContent>
              <Form
                action={`/matrix/settings/devices/${encoded}`}
                method="post"
                className="flex flex-col gap-3"
              >
                <div className="flex flex-col gap-2">
                  <Label htmlFor="display_name">Display name</Label>
                  <Input
                    id="display_name"
                    name="display_name"
                    defaultValue={device.displayName ?? ""}
                  />
                </div>
                <Button type="submit" className="self-start">
                  Save
                </Button>
              </Form>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Keys</CardTitle>
              <CardDescription>
                {/* Comparing the fingerprint out of band is what verification
                    automates -- showing it is the manual fallback. */}
                Compare the fingerprint with the one shown on the device itself.
              </CardDescription>
            </CardHeader>
            <CardContent className="flex flex-col gap-2 text-sm">
              <div className="flex items-baseline justify-between gap-4">
                <span className="shrink-0 text-muted-foreground">Device ID</span>
                <code className="truncate font-mono text-xs">{device.deviceId}</code>
              </div>
              <div className="flex items-baseline justify-between gap-4">
                <span className="shrink-0 text-muted-foreground">Fingerprint</span>
                <code className="truncate font-mono text-xs">{device.fingerprint ?? "—"}</code>
              </div>
              <div className="flex items-baseline justify-between gap-4">
                <span className="shrink-0 text-muted-foreground">Identity key</span>
                <code className="truncate font-mono text-xs">{device.identityKey ?? "—"}</code>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Actions</CardTitle>
            </CardHeader>
            <CardContent className="flex gap-2">
              {!verified && <Button size="sm">Verify</Button>}
              {!current && (
                <Button size="sm" variant="destructive">
                  Sign out
                </Button>
              )}
              {current && (
                <p className="text-sm text-muted-foreground">
                  This is the device this app runs as; it cannot sign itself out here.
                </p>
              )}
            </CardContent>
          </Card>
        </div>
      </ScrollArea>
    </div>
  )
}
