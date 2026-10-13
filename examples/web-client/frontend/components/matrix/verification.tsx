import { Form, Link } from "@inertiajs/react"

import { Alert, AlertDescription, AlertTitle } from "@/components/reui/alert"
import { Badge } from "@/components/reui/badge"
import { Button } from "@/components/ui/button"
import { ShellHeader } from "@/components/admin/slots"

export type Flow = {
  flowId: string
  userId: string
  displayName: string | null
  deviceId: string | null
  state: string
  live: boolean
  own: boolean
  startedByUs: boolean
  method: string | null
  methods: string[]
  emoji: { symbol: string; name: string }[]
  decimals: number[]
  cancelCode: string | null
  cancelReason: string | null
  roomId: string | null
}

export function flowPath(flow: Flow, step?: string) {
  const base = `/matrix/verification/${encodeURIComponent(flow.flowId)}`

  return step ? `${base}/${step}` : base
}

export function Who({ flow }: { flow: Flow }) {
  return (
    <div className="flex flex-col gap-1">
      <span className="text-sm font-medium">{flow.displayName || flow.userId}</span>
      <span className="font-mono text-xs text-muted-foreground">
        {flow.own ? flow.deviceId || "every session" : flow.userId}
      </span>
    </div>
  )
}

export function Act({
  flow,
  action,
  children,
  variant,
  code,
  returnTo,
  disabled,
  fields,
}: {
  flow: Flow
  action: string
  children: React.ReactNode
  variant?: "default" | "outline" | "destructive" | "ghost"
  code?: string
  returnTo?: string
  disabled?: boolean
  fields?: Record<string, string>
}) {
  return (
    <Form action={flowPath(flow)} method="post">
      {({ processing }) => (
        <>
          <input type="hidden" name="action" value={action} />
          {code ? <input type="hidden" name="code" value={code} /> : null}
          {returnTo ? <input type="hidden" name="return_to" value={returnTo} /> : null}
          {Object.entries(fields || {}).map(([name, value]) => (
            <input key={name} type="hidden" name={name} value={value} />
          ))}
          <Button type="submit" size="sm" variant={variant} disabled={processing || disabled}>
            {children}
          </Button>
        </>
      )}
    </Form>
  )
}

export function Step({
  flow,
  title,
  back,
  children,
}: {
  flow: Flow
  title: string
  back?: string
  children: React.ReactNode
}) {
  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <ShellHeader>
        <Link
          href={back || "/matrix/verification"}
          className="text-muted-foreground hover:text-foreground"
        >
          ←
        </Link>
        <h1 className="truncate text-sm font-medium">{title}</h1>
        <Badge variant="secondary" size="sm" className="ml-auto">
          {flow.state}
        </Badge>
      </ShellHeader>

      <div className="mx-auto flex w-full max-w-md flex-col gap-4 p-6">
        <Who flow={flow} />
        {children}
      </div>
    </div>
  )
}

export function Stale({ flow }: { flow: Flow }) {
  return (
    <Alert variant="warning">
      <AlertTitle>This is not where the flow is any more</AlertTitle>
      <AlertDescription>
        It moved on to <code>{flow.state}</code>.{" "}
        <Link href={flowPath(flow)} className="underline">
          Catch up
        </Link>
      </AlertDescription>
    </Alert>
  )
}
