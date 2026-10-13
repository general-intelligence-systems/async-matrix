# frozen_string_literal: true


get "/" do
  room = Models::Matrix::Room.first(room_id: params["roomId"]) || halt(404, "matrix: no such room\n")

  render(
    "matrix/rooms/[roomId]/upgrade",
    roomId:    room.room_id,
    roomTitle: room.title,
    version:   room.room_version || "unknown",
    successor: room.successor_room_id,
  )
end

post "/" do
  halt(501, "matrix: not implemented\n")
end

__END__

import { Form, Head, Link } from "@inertiajs/react"
import { ArrowLeft } from "lucide-react"

import { Alert, AlertDescription, AlertTitle } from "@/components/reui/alert"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Label } from "@/components/ui/label"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import { ShellHeader } from "@/components/admin/slots"

export default function MatrixRoomUpgrade({
  roomId,
  roomTitle,
  version,
  successor,
}: {
  roomId: string
  roomTitle: string
  version: string
  successor: string | null
}) {
  const encoded = encodeURIComponent(roomId)

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title={`Upgrade · ${roomTitle}`} />

      <ShellHeader>
        <Link href={`/matrix/rooms/${encoded}/about`} className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">Upgrade room</h1>
      </ShellHeader>

      <div className="mx-auto flex w-full max-w-xl flex-col gap-4 p-6">
        {successor ? (
          <Alert variant="warning">
            <AlertTitle>Already upgraded</AlertTitle>
            <AlertDescription>
              This room was replaced. Its successor is{" "}
              <Link
                href={`/matrix/rooms/${encodeURIComponent(successor)}`}
                className="font-mono underline"
              >
                {successor}
              </Link>
              .
            </AlertDescription>
          </Alert>
        ) : (
          <>
            {/* Irreversible: the old room is tombstoned and stays read-only
                forever. Said before the control, not after it. */}
            <Alert variant="destructive">
              <AlertTitle>This cannot be undone</AlertTitle>
              <AlertDescription>
                Upgrading creates a new room and closes this one. The history stays here and is
                not copied across, and everyone has to join the replacement.
              </AlertDescription>
            </Alert>

            <Card>
              <CardHeader>
                <CardTitle className="text-sm">New version</CardTitle>
                <CardDescription>This room is on version {version}.</CardDescription>
              </CardHeader>
              <CardContent>
                <Form
                  action={`/matrix/rooms/${encoded}/upgrade`}
                  method="post"
                  className="flex flex-col gap-4"
                >
                  <div className="flex flex-col gap-2">
                    <Label htmlFor="version">Upgrade to</Label>
                    <Select name="new_version" defaultValue="11">
                      <SelectTrigger id="version">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        {["9", "10", "11", "12"].map((option) => (
                          <SelectItem key={option} value={option}>
                            Version {option}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>
                  <Button type="submit" variant="destructive" className="self-start">
                    Upgrade room
                  </Button>
                </Form>
              </CardContent>
            </Card>
          </>
        )}
      </div>
    </div>
  )
}
