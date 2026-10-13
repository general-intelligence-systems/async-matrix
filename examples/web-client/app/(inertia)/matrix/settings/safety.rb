# frozen_string_literal: true


get "/" do
  ignored = Models::Matrix::AccountData
    .content_for(event_type: Models::Matrix::AccountData::IGNORED_USERS).to_h
  previews = Models::Matrix::AccountData.content_for(event_type: "m.media_previews").to_h

  render(
    "matrix/settings/safety",
    ignored:       ignored["ignored_users"].to_h.keys.sort,
    mediaPreviews: previews["media_previews"] || "private",
    inviteAvatars: (previews["invite_avatars"] || "on") == "on",
  )
end

post "/" do
  halt(501, "matrix: not implemented\n")
end

__END__

import { Head, Link } from "@inertiajs/react"
import { ArrowLeft, UserX } from "lucide-react"

import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Empty, EmptyDescription, EmptyHeader, EmptyTitle } from "@/components/ui/empty"
import { Label } from "@/components/ui/label"
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group"
import { ScrollArea } from "@/components/ui/scroll-area"
import { Switch } from "@/components/ui/switch"
import { ShellHeader } from "@/components/admin/slots"

const PREVIEWS = [
  { value: "on", label: "Always", hint: "Show media in every room." },
  { value: "private", label: "Private rooms only", hint: "Hide it in public rooms." },
  { value: "off", label: "Never", hint: "Never load media without asking." },
]

export default function MatrixSettingsSafety({
  ignored,
  mediaPreviews,
  inviteAvatars,
}: {
  ignored: string[]
  mediaPreviews: string
  inviteAvatars: boolean
}) {
  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title="Safety · matrix" />

      <ShellHeader>
        <Link href="/matrix/settings" className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="text-sm font-medium">Safety</h1>
      </ShellHeader>

      <ScrollArea className="min-h-0 flex-1">
        <div className="mx-auto flex w-full max-w-2xl flex-col gap-4 p-6">
          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Ignored users</CardTitle>
              <CardDescription>
                {/* Ignoring hides history too, not just new messages -- the
                    server stops sending their events entirely. */}
                Their messages are hidden everywhere, including ones already sent, and their
                invites are dropped.
              </CardDescription>
            </CardHeader>
            <CardContent className="flex flex-col gap-1">
              {ignored.length === 0 ? (
                <Empty className="py-6">
                  <EmptyHeader>
                    <EmptyTitle className="text-sm">Nobody is ignored</EmptyTitle>
                    <EmptyDescription className="text-xs">
                      Ignore somebody from their profile.
                    </EmptyDescription>
                  </EmptyHeader>
                </Empty>
              ) : (
                ignored.map((userId) => (
                  <div
                    key={userId}
                    className="flex items-center gap-2 rounded-md px-2 py-1.5 hover:bg-accent/50"
                  >
                    <UserX className="size-4 shrink-0 text-muted-foreground" />
                    <Link
                      href={`/matrix/users/${encodeURIComponent(userId)}`}
                      className="flex-1 truncate font-mono text-sm hover:underline"
                    >
                      {userId}
                    </Link>
                    <Button variant="ghost" size="xs">
                      Unignore
                    </Button>
                  </div>
                ))
              )}
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Media previews</CardTitle>
              <CardDescription>
                Loading media tells the sender's server you opened the room.
              </CardDescription>
            </CardHeader>
            <CardContent className="flex flex-col gap-4">
              <RadioGroup defaultValue={mediaPreviews} className="gap-3">
                {PREVIEWS.map((option) => (
                  <div key={option.value} className="flex items-start gap-3">
                    <RadioGroupItem value={option.value} id={`p-${option.value}`} className="mt-0.5" />
                    <div className="flex flex-col gap-0.5">
                      <Label htmlFor={`p-${option.value}`} className="font-normal">
                        {option.label}
                      </Label>
                      <span className="text-xs text-muted-foreground">{option.hint}</span>
                    </div>
                  </div>
                ))}
              </RadioGroup>

              <div className="flex items-center justify-between gap-4 border-t pt-4">
                <div className="flex flex-col gap-0.5">
                  <Label htmlFor="invite_avatars" className="font-normal">
                    Show avatars on invites
                  </Label>
                  <span className="text-xs text-muted-foreground">
                    An invite from a stranger can carry an image.
                  </span>
                </div>
                <Switch id="invite_avatars" defaultChecked={inviteAvatars} />
              </div>
            </CardContent>
          </Card>
        </div>
      </ScrollArea>
    </div>
  )
}
