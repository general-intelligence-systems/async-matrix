# frozen_string_literal: true

get "/" do
  render("matrix/verification", requests: [])
end

__END__

import { Head, Link } from "@inertiajs/react"
import { ShieldCheck } from "lucide-react"

import { Avatar, AvatarFallback } from "@/components/ui/avatar"
import { Button } from "@/components/ui/button"
import { Empty, EmptyDescription, EmptyHeader, EmptyMedia, EmptyTitle } from "@/components/ui/empty"
import { Item, ItemContent, ItemDescription, ItemMedia, ItemTitle } from "@/components/ui/item"
import { Progress } from "@/components/ui/progress"
import { ScrollArea } from "@/components/ui/scroll-area"
import { ShellHeader } from "@/components/admin/slots"

type Request = {
  flowId: string
  userId: string
  displayName: string | null
  state: string
  receivedAt: number
  expiresIn: number
}

export default function MatrixVerification({ requests }: { requests: Request[] }) {
  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title="Verification · matrix" />

      <ShellHeader>
        <h1 className="text-sm font-medium">Verification</h1>
      </ShellHeader>

      <ScrollArea className="min-h-0 flex-1">
        <div className="mx-auto w-full max-w-2xl p-6">
          {requests.length === 0 ? (
            <Empty className="py-12">
              <EmptyHeader>
                <EmptyMedia variant="icon">
                  <ShieldCheck />
                </EmptyMedia>
                <EmptyTitle>No pending requests</EmptyTitle>
                <EmptyDescription>
                  Start one from a device or a profile. Requests expire, so they only appear
                  here while they are live.
                </EmptyDescription>
              </EmptyHeader>
            </Empty>
          ) : (
            <div className="flex flex-col gap-1">
              {requests.map((request) => (
                <Item key={request.flowId}>
                  <ItemMedia>
                    <Avatar className="size-8">
                      <AvatarFallback className="text-[11px]">
                        {(request.displayName ?? request.userId).replace(/^@/, "").charAt(0).toUpperCase()}
                      </AvatarFallback>
                    </Avatar>
                  </ItemMedia>
                  <ItemContent>
                    <ItemTitle>{request.displayName ?? request.userId}</ItemTitle>
                    <ItemDescription>{request.state}</ItemDescription>
                    <Progress value={request.expiresIn} className="mt-1 h-1" />
                  </ItemContent>
                  <Button size="sm" nativeButton={false} render={<Link href={`/matrix/verification/${encodeURIComponent(request.flowId)}`} />}>
                      Continue
                    </Button>
                </Item>
              ))}
            </div>
          )}
        </div>
      </ScrollArea>
    </div>
  )
}
