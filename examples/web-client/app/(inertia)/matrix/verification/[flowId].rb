# frozen_string_literal: true

get "/" do
  render(
    "matrix/verification/[flowId]",
    flowId: params["flowId"].to_s,
    state:  "requested",
    other:  { userId: nil, displayName: nil, deviceId: nil },
    emoji:  [],
  )
end

post "/" do
  halt(501, "matrix: not implemented\n")
end

__END__

import { Head, Link } from "@inertiajs/react"
import { ArrowLeft, Check, QrCode, ShieldCheck, X } from "lucide-react"

import { Alert, AlertDescription, AlertTitle } from "@/components/reui/alert"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Label } from "@/components/ui/label"
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group"
import { Spinner } from "@/components/ui/spinner"
import { ShellHeader } from "@/components/admin/slots"

type Emoji = { symbol: string; name: string }

// Fractal's thirteen VerificationStates, collapsed to the five the view
// actually has to draw differently. The rest are waiting states.
const STEPS = [
  { key: "requested", label: "Request" },
  { key: "ready", label: "Method" },
  { key: "sas", label: "Compare" },
  { key: "done", label: "Done" },
]

export default function MatrixVerificationFlow({
  flowId,
  state,
  other,
  emoji,
}: {
  flowId: string
  state: string
  other: { userId: string | null; displayName: string | null; deviceId: string | null }
  emoji: Emoji[]
}) {
  const who = other.displayName ?? other.userId ?? "the other device"
  const index = Math.max(0, STEPS.findIndex((step) => step.key === state))
  const cancelled = state === "cancelled" || state === "error" || state === "room_left"

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title="Verification · matrix" />

      <ShellHeader>
        <Link href="/matrix/verification" className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="text-sm font-medium">Verify {who}</h1>
      </ShellHeader>

      <div className="mx-auto flex w-full max-w-xl flex-col gap-4 p-6">
        {/* The stepper, as a progress rail rather than a control -- the state
            is the server's, so a step is never something you click back to. */}
        <ol className="flex items-center gap-2">
          {STEPS.map((step, position) => (
            <li key={step.key} className="flex flex-1 items-center gap-2">
              <span
                className={
                  position <= index
                    ? "flex size-6 shrink-0 items-center justify-center rounded-full bg-primary text-xs text-primary-foreground"
                    : "flex size-6 shrink-0 items-center justify-center rounded-full border text-xs text-muted-foreground"
                }
              >
                {position < index ? <Check className="size-3" /> : position + 1}
              </span>
              <span className="truncate text-xs text-muted-foreground">{step.label}</span>
              {position < STEPS.length - 1 && <span className="h-px flex-1 bg-border" />}
            </li>
          ))}
        </ol>

        {cancelled ? (
          <Alert variant="destructive">
            <AlertTitle>Verification cancelled</AlertTitle>
            <AlertDescription>
              Either side can cancel, and a cancelled flow cannot be resumed. Start a new one.
            </AlertDescription>
          </Alert>
        ) : state === "done" ? (
          <Card>
            <CardContent className="flex flex-col items-center gap-3 py-10">
              <ShieldCheck className="size-10 text-primary" />
              <p className="text-sm font-medium">Verified</p>
              <p className="text-center text-sm text-muted-foreground">
                {who} is confirmed. Messages between you are now marked as trusted.
              </p>
              <Button size="sm" nativeButton={false} render={<Link href="/matrix/settings/devices" />}>Done</Button>
            </CardContent>
          </Card>
        ) : state === "sas" ? (
          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Compare the emoji</CardTitle>
              <CardDescription>
                {/* If they differ, somebody is in the middle -- which is the
                    whole point of the exercise, so the warning is not hedged. */}
                Both devices should show the same seven, in the same order. If they do not,
                stop: the connection is being intercepted.
              </CardDescription>
            </CardHeader>
            <CardContent className="flex flex-col gap-4">
              <div className="grid grid-cols-4 gap-3 sm:grid-cols-7">
                {emoji.length === 0
                  ? Array.from({ length: 7 }).map((_, position) => (
                      <div
                        key={position}
                        className="flex aspect-square items-center justify-center rounded-md border bg-muted/40"
                      />
                    ))
                  : emoji.map((item) => (
                      <div
                        key={item.name}
                        className="flex aspect-square flex-col items-center justify-center gap-1 rounded-md border"
                      >
                        <span className="text-2xl">{item.symbol}</span>
                        <span className="text-[10px] text-muted-foreground">{item.name}</span>
                      </div>
                    ))}
              </div>
              <div className="flex gap-2">
                <Button size="sm">
                  <Check className="size-4" />
                  They match
                </Button>
                <Button size="sm" variant="destructive">
                  <X className="size-4" />
                  They do not
                </Button>
              </div>
            </CardContent>
          </Card>
        ) : state === "ready" ? (
          <Card>
            <CardHeader>
              <CardTitle className="text-sm">How to verify</CardTitle>
            </CardHeader>
            <CardContent className="flex flex-col gap-4">
              <RadioGroup defaultValue="sas" className="gap-3">
                <div className="flex items-start gap-3">
                  <RadioGroupItem value="sas" id="m-sas" className="mt-0.5" />
                  <div className="flex flex-col gap-0.5">
                    <Label htmlFor="m-sas" className="font-normal">Compare emoji</Label>
                    <span className="text-xs text-muted-foreground">
                      Works when you can see both screens.
                    </span>
                  </div>
                </div>
                <div className="flex items-start gap-3">
                  <RadioGroupItem value="qr" id="m-qr" className="mt-0.5" />
                  <div className="flex flex-col gap-0.5">
                    <Label htmlFor="m-qr" className="font-normal">
                      <QrCode className="mr-1 inline size-3.5" />
                      Scan a QR code
                    </Label>
                    <span className="text-xs text-muted-foreground">
                      Needs a camera on one of the two devices.
                    </span>
                  </div>
                </div>
              </RadioGroup>
              <Button size="sm" className="self-start">
                Continue
              </Button>
            </CardContent>
          </Card>
        ) : (
          <Card>
            <CardContent className="flex flex-col items-center gap-3 py-10">
              <Spinner />
              <p className="text-sm font-medium">Waiting for {who}</p>
              <p className="text-center text-sm text-muted-foreground">
                They have to accept the request on their end before this can continue.
              </p>
              <Button size="sm" variant="outline">
                Cancel request
              </Button>
            </CardContent>
          </Card>
        )}

        <code className="text-center font-mono text-[10px] text-muted-foreground">{flowId}</code>
      </div>
    </div>
  )
}
