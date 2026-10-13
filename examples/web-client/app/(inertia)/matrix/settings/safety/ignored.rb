# frozen_string_literal: true

# /matrix/settings/safety/ignored — Ignored users
#
# Fractal: account_settings/safety_page/ignored_users_subpage/
#
# The m.ignored_user_list, as a list you can remove from.
# ── Fractal's widget tree ──────────────────────────────────────────────────
#
# COMPONENT NAMES ONLY, extracted from the Blueprint sources named below --
# properties, bindings, styles and handlers are dropped. This is the STRUCTURE
# to rebuild, not a prescription: an Adw.ActionRow is a GTK list row, and what
# it becomes in shadcn/reui is the next decision, not one this records.
#
# Adw.* is libadwaita, which is where the patterns live (PreferencesPage ->
# PreferencesGroup -> ActionRow is GNOME's settings idiom). Gtk.* is plain
# GTK. A bare <Name> with no prefix is one of Fractal's own widgets, and gets
# its own tree below if this view is where it is built.
#
# account_settings/safety_page/ignored_users_subpage/mod.blp
#
#   <Adw.NavigationPage id="IgnoredUsersSubpage">
#     <Gtk.Stack id="stack">
#       <Gtk.StackPage>
#         <Adw.ToolbarView slot="child">
#           <Adw.HeaderBar>
#             <Gtk.ToggleButton id="search_button" />
#           </Adw.HeaderBar>
#           <Gtk.SearchBar id="search_bar">
#             <Adw.Clamp slot="child">
#               <Gtk.SearchEntry id="search_entry" />
#             </Adw.Clamp>
#           </Gtk.SearchBar>
#           <Gtk.ScrolledWindow slot="content">
#             <Adw.ClampScrollable slot="child">
#               <Gtk.ListView id="list_view" slot="child" />
#             </Adw.ClampScrollable>
#           </Gtk.ScrolledWindow>
#         </Adw.ToolbarView>
#       </Gtk.StackPage>
#       <Gtk.StackPage>
#         <Adw.ToolbarView slot="child">
#           <Adw.HeaderBar />
#           <Adw.StatusPage slot="content" />
#         </Adw.ToolbarView>
#       </Gtk.StackPage>
#     </Gtk.Stack>
#   </Adw.NavigationPage>
#

get "/" do
  ignored = Models::Matrix::AccountData
    .content_for(event_type: Models::Matrix::AccountData::IGNORED_USERS).to_h

  render(
    "matrix/settings/safety/ignored",
    users: ignored["ignored_users"].to_h.keys.sort.map{|user_id|
      profile = Models::Matrix::GlobalProfile.first(matrix_user_id: user_id)

      { userId: user_id, name: profile&.display_name || user_id, avatarUrl: profile&.avatar_url }
    },
  )
end

post "/" do
  act! do
    case params["action"].to_s
    in "unignore"
      Matrix::RoomActions.unignore_user(params["user_id"].to_s)
    else
      halt(400, "matrix: no such action\n")
    end
  end
end

__END__

import { Head, Link, router } from "@inertiajs/react"
import { ArrowLeft } from "lucide-react"

import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { Empty, EmptyDescription, EmptyHeader, EmptyTitle } from "@/components/ui/empty"
import { Item, ItemContent, ItemDescription, ItemTitle } from "@/components/ui/item"
import { ShellHeader } from "@/components/admin/slots"

export default function MatrixSettingsIgnored({
  users,
}: {
  users: { userId: string; name: string; avatarUrl: string | null }[]
}) {
  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title="Ignored Users · matrix" />

      <ShellHeader>
        <Link href="/matrix/settings/safety" className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">Ignored Users</h1>
      </ShellHeader>

      <div className="mx-auto flex w-full max-w-xl flex-col gap-4 p-6">
        {users.length === 0 ? (
          <Empty className="py-16">
            <EmptyHeader>
              <EmptyTitle>No Ignored Users</EmptyTitle>
              <EmptyDescription>
                Ignoring someone hides their messages everywhere, from this account.
              </EmptyDescription>
            </EmptyHeader>
          </Empty>
        ) : (
          <Card>
            <CardContent className="flex flex-col gap-2 pt-6">
              {users.map((user) => (
                <Item key={user.userId}>
                  <Avatar className="size-8">
                    {user.avatarUrl && <AvatarImage src={user.avatarUrl} alt="" />}
                    <AvatarFallback className="text-[11px]">
                      {user.name.replace(/^@/, "").charAt(0).toUpperCase()}
                    </AvatarFallback>
                  </Avatar>
                  <ItemContent>
                    <ItemTitle>{user.name}</ItemTitle>
                    <ItemDescription className="font-mono text-xs">{user.userId}</ItemDescription>
                  </ItemContent>
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={() =>
                      router.post("/matrix/settings/safety/ignored", {
                        action: "unignore",
                        user_id: user.userId,
                      })
                    }
                  >
                    Stop ignoring
                  </Button>
                </Item>
              ))}
            </CardContent>
          </Card>
        )}
      </div>
    </div>
  )
}
