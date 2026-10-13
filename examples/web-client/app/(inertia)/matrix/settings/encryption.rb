# frozen_string_literal: true


get "/" do
  credential = Models::Matrix::Credential.first
  identity = Models::Matrix::UserIdentity.first(matrix_user_id: credential&.matrix_user_id)
  own_devices = Models::Matrix::Device.of_user(credential&.matrix_user_id).live

  render(
    "matrix/settings/encryption",
    crossSigning: {
      present:  !identity.nil?,
      master:   identity&.cross_signed? || false,
      verified: identity&.verified || false,
    },
    recovery:     {
      configured: Models::Matrix::SecretsInbox
        .named(Models::Matrix::SecretsInbox::MEGOLM_BACKUP).any?,
    },
    unverified:   own_devices.exclude(trust_state: Models::Matrix::Device::VERIFIED).count,
    backedUp:     Models::Matrix::MegolmInboundSession.where(backed_up: true).count,
    total:        Models::Matrix::MegolmInboundSession.count,
  )
end

post "/" do
  halt(501, "matrix: not implemented\n")
end

__END__

import { Head, Link } from "@inertiajs/react"
import { ArrowLeft, KeyRound, ShieldAlert, ShieldCheck } from "lucide-react"

import { Alert, AlertDescription, AlertTitle } from "@/components/reui/alert"
import { Badge } from "@/components/reui/badge"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Progress } from "@/components/ui/progress"
import { ScrollArea } from "@/components/ui/scroll-area"
import { ShellHeader } from "@/components/admin/slots"

export default function MatrixSettingsEncryption({
  crossSigning,
  recovery,
  unverified,
  backedUp,
  total,
}: {
  crossSigning: { present: boolean; master: boolean; verified: boolean }
  recovery: { configured: boolean }
  unverified: number
  backedUp: number
  total: number
}) {
  const percent = total > 0 ? Math.round((backedUp / total) * 100) : 0

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title="Encryption · matrix" />

      <ShellHeader>
        <Link href="/matrix/settings" className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="text-sm font-medium">Encryption</h1>
      </ShellHeader>

      <ScrollArea className="min-h-0 flex-1">
        <div className="mx-auto flex w-full max-w-2xl flex-col gap-4 p-6">
          {unverified > 0 && (
            <Alert variant="destructive">
              <AlertTitle>
                {unverified} unverified {unverified === 1 ? "session" : "sessions"}
              </AlertTitle>
              <AlertDescription>
                Each one can read everything sent to this account. Verify or sign them out.{" "}
                <Link href="/matrix/settings/devices" className="underline">
                  Review devices
                </Link>
              </AlertDescription>
            </Alert>
          )}

          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-sm">
                {crossSigning.verified ? (
                  <ShieldCheck className="size-4 text-primary" />
                ) : (
                  <ShieldAlert className="size-4 text-muted-foreground" />
                )}
                Cross-signing
              </CardTitle>
              <CardDescription>
                How other people's clients know a device is really yours.
              </CardDescription>
            </CardHeader>
            <CardContent className="flex flex-col gap-3">
              <div className="flex items-center justify-between gap-4 text-sm">
                <span className="text-muted-foreground">Identity</span>
                <Badge variant={crossSigning.present ? "primary" : "secondary"} size="sm">
                  {crossSigning.present ? "Set up" : "Not set up"}
                </Badge>
              </div>
              <div className="flex items-center justify-between gap-4 text-sm">
                <span className="text-muted-foreground">This session</span>
                <Badge variant={crossSigning.verified ? "primary" : "destructive"} size="sm">
                  {crossSigning.verified ? "Verified" : "Unverified"}
                </Badge>
              </div>
              {!crossSigning.present && (
                <Button size="sm" className="self-start">
                  Set up cross-signing
                </Button>
              )}
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-sm">
                <KeyRound className="size-4" />
                Recovery
              </CardTitle>
              <CardDescription>
                {/* Losing this loses every message ever encrypted to this
                    device -- the pickle key is not recoverable from anywhere. */}
                A recovery key restores your message history on a new device. There is no way
                back without it.
              </CardDescription>
            </CardHeader>
            <CardContent className="flex flex-col gap-3">
              <div className="flex items-center justify-between gap-4 text-sm">
                <span className="text-muted-foreground">Recovery key</span>
                <Badge variant={recovery.configured ? "primary" : "secondary"} size="sm">
                  {recovery.configured ? "Stored" : "Not set"}
                </Badge>
              </div>
              <div className="flex gap-2">
                <Button size="sm" variant={recovery.configured ? "outline" : "default"}>
                  {recovery.configured ? "Change recovery key" : "Set up recovery"}
                </Button>
                {recovery.configured && (
                  <Button size="sm" variant="ghost">
                    Reveal
                  </Button>
                )}
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Key backup</CardTitle>
              <CardDescription>
                Room keys stored on the server so history survives losing this device.
              </CardDescription>
            </CardHeader>
            <CardContent className="flex flex-col gap-3">
              <div className="flex items-center justify-between gap-4 text-sm">
                <span className="text-muted-foreground">Backed up</span>
                <span className="tabular-nums">
                  {backedUp} / {total}
                </span>
              </div>
              <Progress value={percent} />
            </CardContent>
          </Card>
        </div>
      </ScrollArea>
    </div>
  )
}
