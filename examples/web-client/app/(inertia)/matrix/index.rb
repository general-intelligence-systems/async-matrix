# frozen_string_literal: true

get "/" do
  render("matrix/index", roomCount: Models::Matrix::Room.count)
end

__END__

import { Head, Link } from "@inertiajs/react"
import { MessagesSquare, Search } from "lucide-react"

import { Button } from "@/components/ui/button"
import {
  Empty,
  EmptyContent,
  EmptyDescription,
  EmptyHeader,
  EmptyMedia,
  EmptyTitle,
} from "@/components/ui/empty"
import { ShellHeader } from "@/components/admin/slots"

export default function MatrixIndex({ roomCount }: { roomCount: number }) {
  return (
    <>
      <Head title="Matrix" />

      <ShellHeader>
        <MessagesSquare className="size-4 shrink-0 text-muted-foreground" />
        <h1 className="truncate text-sm font-medium">Matrix</h1>
      </ShellHeader>

      <Empty className="flex-1">
        <EmptyHeader>
          <EmptyMedia variant="icon">
            <MessagesSquare />
          </EmptyMedia>
          <EmptyTitle>{roomCount > 0 ? "No room selected" : "No rooms yet"}</EmptyTitle>
          <EmptyDescription>
            {roomCount > 0
              ? "Pick a room from the sidebar to read it."
              : "Join or create a room, or wait for the device to finish its first sync."}
          </EmptyDescription>
        </EmptyHeader>
        <EmptyContent>
          <div className="flex gap-2">
            <Button nativeButton={false} render={<Link href="/matrix/rooms/new" />}>New room</Button>
            <Button variant="outline" nativeButton={false} render={<Link href="/matrix/explore" />}>
<Search className="size-4" />
                Explore
              </Button>
          </div>
        </EmptyContent>
      </Empty>
    </>
  )
}
