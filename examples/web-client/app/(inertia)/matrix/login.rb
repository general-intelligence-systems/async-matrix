# frozen_string_literal: true

require "digest"


MAS_URL           = ENV["MAS_URL"].to_s
MAS_CLIENT_ID     = ENV["MAS_CLIENT_ID"].to_s
MAS_CLIENT_SECRET = ENV["MAS_CLIENT_SECRET"].to_s
MATRIX_HOMESERVER = ENV.fetch("MATRIX_HOMESERVER_URL", "https://chat.kremlin.email")

MATRIX_API_SCOPE    = "urn:matrix:org.matrix.msc2967.client:api:*"
MATRIX_DEVICE_SCOPE = "urn:matrix:org.matrix.msc2967.client:device:"

helpers do
  def mas_configured? = !MAS_URL.empty? && !MAS_CLIENT_ID.empty? && !MAS_CLIENT_SECRET.empty?

  def mas_redirect_uri = ENV.fetch("MAS_REDIRECT_URI", "#{request.base_url}/matrix/callback")

  def mas_scope(device_id) = "#{MATRIX_API_SCOPE} #{MATRIX_DEVICE_SCOPE}#{device_id}"

  def mas_device_id
    existing = Models::Matrix::Credential.first&.device_id.to_s
    existing.empty? ? Models::Matrix::Credential.generate_device_id : existing
  end
end

get "/" do
  credential = Models::Matrix::Credential.first

  render(
    "matrix/login",
    configured: mas_configured?,
    missing:    {
      url:    MAS_URL.empty?,
      id:     MAS_CLIENT_ID.empty?,
      secret: MAS_CLIENT_SECRET.empty?,
    },
    homeserver:  MATRIX_HOMESERVER,
    redirectUri: mas_redirect_uri,
    connected:   credential&.usable? || false,
    account:     {
      userId:   credential&.matrix_user_id,
      deviceId: credential&.device_id,
    },
    error: session.delete(:matrix_login_error),
  )
end

post "/" do
  unless mas_configured?
    halt(503, "matrix: MAS_URL, MAS_CLIENT_ID and MAS_CLIENT_SECRET must be set\n")
  end

  verifier  = SecureRandom.urlsafe_base64(48)
  challenge = Base64.urlsafe_encode64(Digest::SHA256.digest(verifier), padding: false)
  state     = SecureRandom.urlsafe_base64(32)
  device_id = mas_device_id

  session[:matrix_oidc] = {
    "verifier"  => verifier,
    "state"     => state,
    "device_id" => device_id,
    "redirect"  => mas_redirect_uri,
  }

  query = URI.encode_www_form(
    client_id:             MAS_CLIENT_ID,
    redirect_uri:          mas_redirect_uri,
    response_type:         "code",
    scope:                 mas_scope(device_id),
    code_challenge:        challenge,
    code_challenge_method: "S256",
    state:                 state,
  )

  redirect("#{MAS_URL.chomp("/")}/authorize?#{query}", 303)
end

__END__

import { Form, Head, Link } from "@inertiajs/react"
import { CircleCheck, KeyRound, TriangleAlert } from "lucide-react"

import { Alert, AlertDescription, AlertTitle } from "@/components/reui/alert"
import { Badge } from "@/components/reui/badge"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import {
  Empty,
  EmptyContent,
  EmptyDescription,
  EmptyHeader,
  EmptyMedia,
  EmptyTitle,
} from "@/components/ui/empty"

export default function MatrixLogin({
  configured,
  missing,
  homeserver,
  redirectUri,
  connected,
  account,
  error,
}: {
  configured: boolean
  missing: { url: boolean; id: boolean; secret: boolean }
  homeserver: string
  redirectUri: string
  connected: boolean
  account: { userId: string | null; deviceId: string | null }
  error: string | null
}) {
  const absent = [
    missing.url && "MAS_URL",
    missing.id && "MAS_CLIENT_ID",
    missing.secret && "MAS_CLIENT_SECRET",
  ].filter(Boolean)

  return (
    <div className="flex min-h-0 flex-1 items-center justify-center p-6">
      <Head title="Connect Matrix" />

      <div className="flex w-full max-w-md flex-col gap-4">
        {error && (
          <Alert variant="destructive">
            <AlertTitle>Sign-in failed</AlertTitle>
            <AlertDescription>{error}</AlertDescription>
          </Alert>
        )}

        {connected ? (
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-sm">
                <CircleCheck className="size-4 text-primary" />
                Connected
              </CardTitle>
              <CardDescription>This controller has a Matrix device.</CardDescription>
            </CardHeader>
            <CardContent className="flex flex-col gap-3">
              <div className="flex items-center justify-between gap-4 text-sm">
                <span className="text-muted-foreground">Account</span>
                <code className="truncate font-mono text-xs">{account.userId}</code>
              </div>
              <div className="flex items-center justify-between gap-4 text-sm">
                <span className="text-muted-foreground">Device</span>
                <Badge variant="secondary" size="sm" className="font-mono">
                  {account.deviceId}
                </Badge>
              </div>
              <div className="flex gap-2">
                <Button size="sm" nativeButton={false} render={<Link href="/matrix" />}>Open Matrix</Button>
                {/* Re-authenticating keeps the device id, so it costs nothing
                    but a round trip -- no keys are lost. */}
                <Form action="/matrix/login" method="post">
                  <Button type="submit" size="sm" variant="outline">
                    Re-authenticate
                  </Button>
                </Form>
              </div>
            </CardContent>
          </Card>
        ) : (
          <Empty className="rounded-lg border py-10">
            <EmptyHeader>
              <EmptyMedia variant="icon">
                <KeyRound />
              </EmptyMedia>
              <EmptyTitle>Connect to Matrix</EmptyTitle>
              <EmptyDescription>
                You will be sent to the homeserver's sign-in, and back here once it is done.
                This happens once: the device it creates is kept.
              </EmptyDescription>
            </EmptyHeader>
            <EmptyContent>
              <Form action="/matrix/login" method="post">
                <Button type="submit" disabled={!configured}>
                  Continue to sign in
                </Button>
              </Form>
            </EmptyContent>
          </Empty>
        )}

        {!configured && (
          <Alert variant="warning">
            <TriangleAlert className="size-4" />
            <AlertTitle>Not configured</AlertTitle>
            <AlertDescription>
              <p>Set {absent.join(", ")} before signing in.</p>
              <p className="mt-2">
                The client also needs this exact redirect URI registered:
                <code className="mt-1 block font-mono text-xs break-all">{redirectUri}</code>
              </p>
            </AlertDescription>
          </Alert>
        )}

        <p className="text-center text-xs text-muted-foreground">
          Homeserver <code className="font-mono">{homeserver}</code>
        </p>
      </div>
    </div>
  )
}
