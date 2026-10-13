# frozen_string_literal: true

# /matrix/settings/devices/:deviceId — Device
#
# Fractal: account_settings/user_session/
#
# NOT IMPLEMENTED.
#
# One of our devices: rename, verify, or sign out.
# ── Fractal's widget tree ──────────────────────────────────────────────────
#
# COMPONENT NAMES ONLY, extracted from the Blueprint sources named below --
# properties, bindings, styles and handlers are dropped. This is the STRUCTURE
# to rebuild, not a prescription: an Adw.ActionRow is a GTK list row, and what
# it becomes in shadcn/reui is the next decision, not one this records.
#
# Adw.* is libadwaita, which is where the patterns live (PreferencesPage ->
# PreferencesGroup -> ActionRow is GNOME's settings idiom). Gtk.* is plain
# GTK. A bare <Name> with no prefix is one of Fractal's own widgets, and gets
# its own tree below if this view is where it is built.
#
# account_settings/user_session/user_session_subpage.blp
#
#   <Adw.NavigationPage id="UserSessionSubpage">
#     <Adw.ToolbarView slot="child">
#       <Adw.HeaderBar />
#       <Adw.PreferencesPage slot="content">
#         <Adw.PreferencesGroup>
#           <CopyableRow />
#           <Adw.EntryRow id="display_name">
#             <ActionButton id="display_name_button" />
#           </Adw.EntryRow>
#           <Adw.ActionRow id="verified_status" />
#           <Adw.ActionRow />
#           <Adw.ActionRow />
#         </Adw.PreferencesGroup>
#         <Adw.PreferencesGroup>
#           <Adw.ButtonRow id="log_out_button" />
#           <LoadingButtonRow id="loading_disconnect_button" />
#           <Adw.ButtonRow id="open_url_disconnect_button" />
#         </Adw.PreferencesGroup>
#       </Adw.PreferencesPage>
#     </Adw.ToolbarView>
#   </Adw.NavigationPage>
#
# ── Build with ─────────────────────────────────────────────────────────────
#
# @reui/profile-10 — one key, revealed, renamed, revoked. A device is the same object.
#
#   UserSessionSubpage    ->  ui/card with ui/field rows
#   rename                ->  ui/input, inline save
#   device/identity keys  ->  ui/item + copy, monospace
#   sign out              ->  ui/alert-dialog
#   verify                ->  ui/button -> /matrix/verification/:flowId
#

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
      lastSeenTs:  device.last_seen_ts,
      lastSeenIp:  device.last_seen_ip,
    },
  )
end

post "/" do
  device_id = params["deviceId"].to_s

  act! do
    case params["action"].to_s
    when "delete"
      Matrix::RoomActions.delete_device(device_id)
    else
      Matrix::RoomActions.rename_device(device_id, params["display_name"].to_s)
    end
  end
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
    lastSeenTs: number | null
    lastSeenIp: string | null
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
                  <Label htmlFor="display_name">Public Name</Label>
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
                <span className="shrink-0 text-muted-foreground">Matrix Session ID</span>
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
              {/* Both come from GET /devices, which is the only place the homeserver reports
                  them, so they are blank until that has been fetched at least once. */}
              <div className="flex items-baseline justify-between gap-4">
                <span className="shrink-0 text-muted-foreground">Last Seen</span>
                <span className="truncate text-xs">
                  {device.lastSeenTs ? new Date(device.lastSeenTs).toLocaleString() : "—"}
                </span>
              </div>
              <div className="flex items-baseline justify-between gap-4">
                <span className="shrink-0 text-muted-foreground">Last Location</span>
                <code className="truncate font-mono text-xs">{device.lastSeenIp ?? "—"}</code>
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
