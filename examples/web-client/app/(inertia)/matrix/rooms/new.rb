# frozen_string_literal: true

get "/" do
  render("matrix/rooms/new")
end

post "/" do
  halt(501, "matrix: not implemented\n")
end

__END__

import { Form, Head, Link } from "@inertiajs/react"
import { ArrowLeft } from "lucide-react"

import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group"
import { ScrollArea } from "@/components/ui/scroll-area"
import { Switch } from "@/components/ui/switch"
import { Textarea } from "@/components/ui/textarea"
import { ShellHeader } from "@/components/admin/slots"

export default function MatrixNewRoom() {
  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title="New room · matrix" />

      <ShellHeader>
        <Link href="/matrix" className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="text-sm font-medium">New room</h1>
      </ShellHeader>

      <ScrollArea className="min-h-0 flex-1">
        <Form
          action="/matrix/rooms/new"
          method="post"
          className="mx-auto flex w-full max-w-xl flex-col gap-4 p-6"
        >
          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Details</CardTitle>
            </CardHeader>
            <CardContent className="flex flex-col gap-4">
              <div className="flex flex-col gap-2">
                <Label htmlFor="name">Name</Label>
                <Input id="name" name="name" placeholder="Ops" autoFocus />
              </div>
              <div className="flex flex-col gap-2">
                <Label htmlFor="topic">Topic</Label>
                <Textarea id="topic" name="topic" rows={2} placeholder="What the room is for" />
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Visibility</CardTitle>
              <CardDescription>This sets the join rule and whether it is published.</CardDescription>
            </CardHeader>
            <CardContent>
              <RadioGroup name="visibility" defaultValue="private" className="gap-3">
                <div className="flex items-start gap-3">
                  <RadioGroupItem value="private" id="v-private" className="mt-0.5" />
                  <div className="flex flex-col gap-0.5">
                    <Label htmlFor="v-private" className="font-normal">Private</Label>
                    <span className="text-xs text-muted-foreground">Invite only, unlisted.</span>
                  </div>
                </div>
                <div className="flex items-start gap-3">
                  <RadioGroupItem value="public" id="v-public" className="mt-0.5" />
                  <div className="flex flex-col gap-0.5">
                    <Label htmlFor="v-public" className="font-normal">Public</Label>
                    <span className="text-xs text-muted-foreground">
                      Anyone can join and it is published in the directory.
                    </span>
                  </div>
                </div>
              </RadioGroup>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Encryption</CardTitle>
              <CardDescription>
                {/* Irreversible, and the spec gives no way back -- worth saying
                    at the point of choosing rather than afterwards. */}
                Encryption cannot be turned off once a room has it.
              </CardDescription>
            </CardHeader>
            <CardContent className="flex items-center justify-between gap-4">
              <Label htmlFor="encrypted" className="font-normal">
                Enable end-to-end encryption
              </Label>
              <Switch id="encrypted" name="encrypted" defaultChecked />
            </CardContent>
          </Card>

          <Button type="submit" className="self-start">
            Create room
          </Button>
        </Form>
      </ScrollArea>
    </div>
  )
}
