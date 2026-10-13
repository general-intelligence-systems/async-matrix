# frozen_string_literal: true

# /matrix/settings/devices — Devices
#
# Fractal: account_settings/user_session/ + session/user_sessions_list/
#
# Our own devices: current first, then the rest, with last-seen IP and time
# and whether each is verified.
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
# account_settings/user_session/user_session_list_subpage.blp
#
#   <Adw.NavigationPage id="UserSessionListSubpage">
#     <Adw.ToolbarView slot="child">
#       <Adw.HeaderBar />
#       <Adw.PreferencesPage slot="content">
#         <Adw.PreferencesGroup id="current_session_group">
#           <Gtk.ListBox id="current_session" />
#         </Adw.PreferencesGroup>
#         <Adw.PreferencesGroup id="other_sessions_group">
#           <Gtk.Stack id="stack">
#             <Gtk.StackPage>
#               <Adw.Spinner slot="child" />
#             </Gtk.StackPage>
#             <Gtk.StackPage>
#               <Gtk.ListBox slot="child" id="other_sessions" />
#             </Gtk.StackPage>
#             <Gtk.StackPage>
#               <Gtk.Box slot="child">
#                 <Gtk.Label />
#                 <Gtk.Button />
#               </Gtk.Box>
#             </Gtk.StackPage>
#           </Gtk.Stack>
#         </Adw.PreferencesGroup>
#       </Adw.PreferencesPage>
#     </Adw.ToolbarView>
#   </Adw.NavigationPage>
#
# account_settings/user_session/user_session_row.blp
#
#   <Gtk.ListBoxRow id="UserSessionRow">
#     <Gtk.Box slot="child">
#       <Gtk.Box>
#         <Gtk.Box id="header">
#           <Gtk.Label />
#           <Gtk.Image />
#           <Gtk.Image />
#         </Gtk.Box>
#         <Gtk.Label />
#       </Gtk.Box>
#       <Gtk.Image />
#     </Gtk.Box>
#   </Gtk.ListBoxRow>
#
# ── Build with ─────────────────────────────────────────────────────────────
#
# @reui/solution-users-2 — "Member Detail Page with Sidebar Tabs for Access,
#   Authentication, and Sessions". Its Sessions tab is this screen: current session
#   first, then the others, each with last-seen and a verification state.
#
#   UserSessionListSubpage  ->  ui/item rows grouped current / other
#   UserSessionRow          ->  ui/item — name, last_seen_ip, last_seen_ts, ui/badge(verified)
#   bulk sign-out           ->  ui/alert-dialog, since it needs UIA re-auth
#   verified / unverified   ->  ui/badge + reui/alert when unverified sessions exist
#

get "/" do
  credential = Models::Matrix::Credential.first

  render(
    "matrix/settings/devices",
    current: credential&.device_id,
    devices: Models::Matrix::Device
      .of_user(credential&.matrix_user_id)
      .live
      .reverse(:first_seen_at)
      .all
      .map do |device|
        {
          deviceId:    device.device_id,
          displayName: device.display_name,
          trust:       device.trust_state,
          firstSeen:   device.first_seen_at,
        }
      end,
  )
end

__END__

import { Head, Link } from "@inertiajs/react"
import { ArrowLeft, BadgeCheck, ShieldQuestion, Smartphone } from "lucide-react"

import { Alert, AlertDescription, AlertTitle } from "@/components/reui/alert"
import { Badge } from "@/components/reui/badge"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Empty, EmptyDescription, EmptyHeader, EmptyTitle } from "@/components/ui/empty"
import { Item, ItemContent, ItemDescription, ItemMedia, ItemTitle } from "@/components/ui/item"
import { ScrollArea } from "@/components/ui/scroll-area"
import { ShellHeader } from "@/components/admin/slots"

type Device = {
  deviceId: string
  displayName: string | null
  trust: string
  firstSeen: number | null
}

export default function MatrixSettingsDevices({
  current,
  devices,
}: {
  current: string | null
  devices: Device[]
}) {
  const others = devices.filter((device) => device.deviceId !== current)
  const unverified = others.filter((device) => device.trust !== "verified").length

  const row = (device: Device, isCurrent: boolean) => (
    <Item key={device.deviceId} render={<Link href={`/matrix/settings/devices/${encodeURIComponent(device.deviceId)}`} />}>
        <ItemMedia variant="icon">
          <Smartphone className="size-4" />
        </ItemMedia>
        <ItemContent>
          <ItemTitle>{device.displayName ?? device.deviceId}</ItemTitle>
          <ItemDescription className="font-mono">{device.deviceId}</ItemDescription>
        </ItemContent>
        <div className="flex shrink-0 items-center gap-2">
          {isCurrent && (
            <Badge variant="outline" size="sm">
              This device
            </Badge>
          )}
          <Badge variant={device.trust === "verified" ? "primary" : "secondary"} size="sm">
            {device.trust === "verified" ? (
              <BadgeCheck className="size-2.5" />
            ) : (
              <ShieldQuestion className="size-2.5" />
            )}
            {device.trust}
          </Badge>
        </div>
      </Item>
  )

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title="Devices · matrix" />

      <ShellHeader>
        <Link href="/matrix/settings" className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="text-sm font-medium">Sessions</h1>
      </ShellHeader>

      <ScrollArea className="min-h-0 flex-1">
        <div className="mx-auto flex w-full max-w-2xl flex-col gap-4 p-6">
          {unverified > 0 && (
            <Alert variant="warning">
              <AlertTitle>
                {unverified} unverified {unverified === 1 ? "device" : "devices"}
              </AlertTitle>
              <AlertDescription>
                Verify the ones you recognise and sign out the ones you do not.
              </AlertDescription>
            </Alert>
          )}

          {devices.length === 0 ? (
            <Empty className="py-12">
              <EmptyHeader>
                <EmptyTitle>No devices stored</EmptyTitle>
                <EmptyDescription>
                  Device keys appear after the first /keys/query.
                </EmptyDescription>
              </EmptyHeader>
            </Empty>
          ) : (
            <>
              {current && (
                <Card>
                  <CardHeader>
                    <CardTitle className="text-sm">Current Session</CardTitle>
                  </CardHeader>
                  <CardContent className="flex flex-col gap-1">
                    {devices
                      .filter((device) => device.deviceId === current)
                      .map((device) => row(device, true))}
                  </CardContent>
                </Card>
              )}

              <Card>
                <CardHeader>
                  <CardTitle className="text-sm">Other Active Sessions</CardTitle>
                  <CardDescription>
                    Everywhere else this account is signed in.
                  </CardDescription>
                </CardHeader>
                <CardContent className="flex flex-col gap-1">
                  {others.length === 0 ? (
                    <p className="py-2 text-sm text-muted-foreground">No other sessions.</p>
                  ) : (
                    others.map((device) => row(device, false))
                  )}
                </CardContent>
              </Card>
            </>
          )}
        </div>
      </ScrollArea>
    </div>
  )
}
