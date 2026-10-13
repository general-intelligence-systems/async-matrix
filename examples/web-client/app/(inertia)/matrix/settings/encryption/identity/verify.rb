# frozen_string_literal: true

# /matrix/settings/encryption/identity/verify — Verify this session
#
# Fractal: components/crypto/identity_setup_view.{blp,rs} (tag verify)
#
# Verification against an existing session, which is what hands this device the cross-signing secrets.
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
# components/crypto/identity_setup_view.blp
#
#   <Adw.NavigationPage>
#     <Adw.ToolbarView slot="child">
#       <Adw.HeaderBar />
#       <IdentityVerificationView id="verification_page" slot="content" />
#     </Adw.ToolbarView>
#   </Adw.NavigationPage>
#

get "/" do
  credential = Models::Matrix::Credential.first

  render(
    "matrix/settings/encryption/identity/verify",
    userId:  credential&.matrix_user_id,
    devices: Models::Matrix::Device
      .of_user(credential&.matrix_user_id)
      .live
      .exclude(device_id: credential&.device_id)
      .reverse(:last_seen_ts)
      .map do |device|
        {
          deviceId:    device.device_id,
          displayName: device.display_name,
          verified:    device.verified?,
          lastSeen:    device.last_seen_ts,
        }
      end,
    pending: Models::Matrix::VerificationFlow
      .live
      .newest_first
      .map{|flow| {flowId: flow.flow_id, userId: flow.other_user_id, state: flow.state}},
  )
end

post "/" do
  credential = Models::Matrix::Credential.first
  device_id = params["device_id"].to_s

  if device_id.empty?
    devices = nil
  else
    devices = [device_id]
  end

  flow = Matrix::Verification.request!(credential&.matrix_user_id, devices)

  redirect("/matrix/verification/#{CGI.escape(flow.flow_id)}/wait", 303)
rescue Matrix::RoomActions::Error => error
  halt(409, "matrix: #{error.message}\n")
end

__END__

import { Form, Head, Link } from "@inertiajs/react"
import { ArrowLeft, ShieldCheck } from "lucide-react"

import { Alert, AlertDescription, AlertTitle } from "@/components/reui/alert"
import { Badge } from "@/components/reui/badge"
import { Button } from "@/components/ui/button"
import { Item, ItemContent, ItemDescription, ItemTitle } from "@/components/ui/item"
import { ShellHeader } from "@/components/admin/slots"

export default function MatrixSettingsEncryptionIdentityVerify({
  userId,
  devices,
  pending,
}: {
  userId: string | null
  devices: { deviceId: string; displayName: string | null; verified: boolean; lastSeen: number | null }[]
  pending: { flowId: string; userId: string; state: string }[]
}) {
  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title="Verify this session" />

      <ShellHeader>
        <Link href="/matrix/settings/encryption/identity" className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">Verify With Another Session</h1>
      </ShellHeader>

      <div className="mx-auto flex w-full max-w-xl flex-col gap-4 p-6">
        <Alert>
          <AlertTitle>Ask a session that already has the keys</AlertTitle>
          <AlertDescription>
            It sends this session the cross-signing secrets once you compare the emoji on both
            screens. {userId}
          </AlertDescription>
        </Alert>

        {pending.length > 0 && (
          <Alert variant="warning">
            <AlertTitle>A verification is already running</AlertTitle>
            <AlertDescription>
              <Link href={`/matrix/verification/${encodeURIComponent(pending[0].flowId)}`} className="underline">
                Continue it
              </Link>{" "}
              instead of starting another.
            </AlertDescription>
          </Alert>
        )}

        {devices.length === 0 ? (
          <Alert variant="warning">
            <AlertTitle>No other session</AlertTitle>
            <AlertDescription>
              Nothing else is signed in to answer, so recovery is the only way back to the keys.
            </AlertDescription>
          </Alert>
        ) : (
          devices.map((device) => (
            <Item key={device.deviceId} variant="outline">
              <ItemContent>
                <ItemTitle className="flex items-center gap-2">
                  {device.displayName || device.deviceId}
                  {device.verified && (
                    <Badge variant="primary" size="sm">
                      <ShieldCheck className="size-3" /> Verified
                    </Badge>
                  )}
                </ItemTitle>
                <ItemDescription className="font-mono text-xs">{device.deviceId}</ItemDescription>
              </ItemContent>
              <Form action="/matrix/settings/encryption/identity/verify" method="post">
                {({ processing }) => (
                  <>
                    <input type="hidden" name="device_id" value={device.deviceId} />
                    <Button type="submit" size="sm" disabled={processing}>
                      Verify
                    </Button>
                  </>
                )}
              </Form>
            </Item>
          ))
        )}

        {devices.length > 1 && (
          <Form action="/matrix/settings/encryption/identity/verify" method="post">
            {({ processing }) => (
              <Button type="submit" variant="outline" size="sm" disabled={processing} className="self-start">
                Ask every session
              </Button>
            )}
          </Form>
        )}
      </div>
    </div>
  )
}
