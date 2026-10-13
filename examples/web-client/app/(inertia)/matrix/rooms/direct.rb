# frozen_string_literal: true

get "/" do
  render("matrix/rooms/direct")
end

post "/" do
  halt(501, "matrix: not implemented\n")
end

__END__

import { Form, Head, Link } from "@inertiajs/react"
import { ArrowLeft, Search } from "lucide-react"

import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Empty, EmptyDescription, EmptyHeader, EmptyTitle } from "@/components/ui/empty"
import {
  InputGroup,
  InputGroupAddon,
  InputGroupInput,
} from "@/components/ui/input-group"
import { ScrollArea } from "@/components/ui/scroll-area"
import { ShellHeader } from "@/components/admin/slots"

export default function MatrixNewDirect() {
  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title="New direct chat · matrix" />

      <ShellHeader>
        <Link href="/matrix" className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="text-sm font-medium">New direct chat</h1>
      </ShellHeader>

      <ScrollArea className="min-h-0 flex-1">
        <div className="mx-auto flex w-full max-w-xl flex-col gap-4 p-6">
          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Who</CardTitle>
              <CardDescription>
                Search the directory, or type a full Matrix ID for somebody on another server.
              </CardDescription>
            </CardHeader>
            <CardContent className="flex flex-col gap-3">
              <Form action="/matrix/rooms/direct" method="post" className="flex flex-col gap-3">
                <InputGroup>
                  <InputGroupAddon>
                    <Search className="size-3.5" />
                  </InputGroupAddon>
                  <InputGroupInput name="user_id" placeholder="@alice:example.org" autoFocus />
                </InputGroup>
                <Button type="submit" className="self-start">
                  Start chat
                </Button>
              </Form>

              <Empty className="py-8">
                <EmptyHeader>
                  <EmptyTitle className="text-sm">No results yet</EmptyTitle>
                  <EmptyDescription className="text-xs">
                    Directory results appear here as you type.
                  </EmptyDescription>
                </EmptyHeader>
              </Empty>
            </CardContent>
          </Card>
        </div>
      </ScrollArea>
    </div>
  )
}
