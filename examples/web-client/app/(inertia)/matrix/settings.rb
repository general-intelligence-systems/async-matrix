# frozen_string_literal: true

# /matrix/settings — Matrix settings
#
# Fractal: account_settings/general_page/
#
# NOT IMPLEMENTED.
#
# The account: display name, avatar, and the homeserver/device this app is
# logged in as (matrix_credentials).
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
# account_settings/mod.blp
#
#   <Adw.PreferencesDialog id="AccountSettings">
#     <AccountSettingsGeneralPage />
#     <NotificationsPage />
#     <SafetyPage />
#     <EncryptionPage />
#   </Adw.PreferencesDialog>
#
# account_settings/general_page/mod.blp
#
#   <Adw.PreferencesPage id="AccountSettingsGeneralPage">
#     <Adw.PreferencesGroup>
#       <EditableAvatar id="avatar" />
#     </Adw.PreferencesGroup>
#     <Adw.PreferencesGroup>
#       <Adw.EntryRow id="display_name">
#         <ActionButton id="display_name_button" />
#       </Adw.EntryRow>
#     </Adw.PreferencesGroup>
#     <Adw.PreferencesGroup>
#       <CopyableRow id="user_id" />
#       <ButtonCountRow id="user_sessions_row" />
#     </Adw.PreferencesGroup>
#     <Adw.PreferencesGroup>
#       <Adw.ButtonRow id="change_password_row" />
#       <Adw.ButtonRow id="manage_account_row" />
#       <Adw.ButtonRow />
#       <Adw.ButtonRow id="deactivate_account_button" />
#     </Adw.PreferencesGroup>
#     <Adw.PreferencesGroup>
#       <Adw.ExpanderRow>
#         <CopyableRow id="homeserver" />
#         <CopyableRow id="session_id" />
#       </Adw.ExpanderRow>
#     </Adw.PreferencesGroup>
#   </Adw.PreferencesPage>
#
# account_settings/general_page/log_out_subpage.blp
#
#   <Adw.NavigationPage id="LogOutSubpage">
#     <Gtk.Stack slot="child" id="stack">
#       <Gtk.StackPage>
#         <Adw.ToolbarView slot="child">
#           <Adw.HeaderBar />
#           <Gtk.ScrolledWindow slot="content">
#             <Adw.Clamp slot="child">
#               <Gtk.Box slot="child">
#                 <Gtk.Image />
#                 <Gtk.Label />
#                 <Gtk.Box id="warning_box">
#                   <Gtk.Label id="warning_description" />
#                   <Gtk.ListBox>
#                     <Adw.ButtonRow id="warning_button" />
#                   </Gtk.ListBox>
#                 </Gtk.Box>
#                 <Gtk.ListBox>
#                   <LoadingButtonRow id="logout_button" />
#                 </Gtk.ListBox>
#               </Gtk.Box>
#             </Adw.Clamp>
#           </Gtk.ScrolledWindow>
#         </Adw.ToolbarView>
#       </Gtk.StackPage>
#       <Gtk.StackPage>
#         <Adw.ToolbarView slot="child">
#           <Adw.HeaderBar />
#           <Gtk.ScrolledWindow slot="content">
#             <Adw.Clamp slot="child">
#               <Gtk.Box slot="child">
#                 <Gtk.Label />
#                 <Gtk.ListBox>
#                   <LoadingButtonRow id="try_again_button" />
#                 </Gtk.ListBox>
#                 <Gtk.Label />
#                 <Gtk.ListBox>
#                   <LoadingButtonRow id="remove_button" />
#                 </Gtk.ListBox>
#               </Gtk.Box>
#             </Adw.Clamp>
#           </Gtk.ScrolledWindow>
#         </Adw.ToolbarView>
#       </Gtk.StackPage>
#     </Gtk.Stack>
#   </Adw.NavigationPage>
#
# account_settings/general_page/deactivate_account_subpage.blp
#
#   <Adw.NavigationPage id="DeactivateAccountSubpage">
#     <Adw.ToolbarView slot="child">
#       <Adw.HeaderBar />
#       <Gtk.ScrolledWindow slot="content" id="scrolled_window">
#         <Adw.Clamp slot="child">
#           <Gtk.Box slot="child" id="box">
#             <Gtk.Image />
#             <Gtk.Box>
#               <Gtk.Label />
#               <Gtk.Label />
#             </Gtk.Box>
#             <Gtk.ListBox>
#               <Adw.EntryRow id="confirmation" />
#               <LoadingButtonRow id="loading_button" />
#               <Adw.ButtonRow id="open_url_button" />
#             </Gtk.ListBox>
#           </Gtk.Box>
#         </Adw.Clamp>
#       </Gtk.ScrolledWindow>
#     </Adw.ToolbarView>
#   </Adw.NavigationPage>
#
# ── Build with ─────────────────────────────────────────────────────────────
#
# @reui/profile-9 — "Account settings hub with grouped collapsible sidebar navigation
#   and 11 swappable form panels". The hub for all five settings routes: its sidebar is
#   the nav, and each of our routes fills the panel.
#
#   Adw.PreferencesWindow sidebar  ->  profile-9's nav; our routes replace its panel swapping
#   general_page rows              ->  ui/field rows in a ui/card
#   EditableAvatar                 ->  ui/avatar + file-upload
#   LogOutSubpage                  ->  ui/alert-dialog
#   DeactivateAccountSubpage       ->  ui/alert-dialog with a typed confirmation
#
# INSTALL, NOT IN EITHER REGISTRY -- reui lists file-upload on its components page but the
#   base-vega registry does not carry it; check the name before relying on it.
#
# The account. One device, so there is no session list -- see _layout.rb.

get "/" do
  credential = Models::Matrix::Credential.first
  # .first, not .current: current mints an Olm account when there is none,
  # and rendering a settings page must not create a crypto identity.
  state = Models::Matrix::DeviceState.first
  profile = Models::Matrix::GlobalProfile.first(matrix_user_id: credential&.matrix_user_id)

  render(
    "matrix/settings",
    account: {
      userId:      credential&.matrix_user_id,
      deviceId:    credential&.device_id,
      homeserver:  credential&.homeserver_url,
      displayName: profile&.display_name,
      avatarUrl:   profile&.avatar_url,
    },
    device:  {
      syncing:       !Models::Matrix::KV.sync_token.nil?,
      keysPublished: state&.keys_published || false,
      otkCount:      state&.otk_count.to_i,
    },
  )
end

post "/" do
  halt(501, "matrix: not implemented\n")
end

__END__

import { Form, Head, Link } from "@inertiajs/react"
import { CircleCheck, CircleX } from "lucide-react"

import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Alert, AlertDescription, AlertTitle } from "@/components/reui/alert"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Item, ItemContent, ItemDescription, ItemTitle } from "@/components/ui/item"
import { Label } from "@/components/ui/label"
import { ScrollArea } from "@/components/ui/scroll-area"
import { ShellHeader } from "@/components/admin/slots"

const SECTIONS = [
  { href: "/matrix/settings/notifications", title: "Notifications", hint: "Push rules and keywords" },
  { href: "/matrix/settings/encryption", title: "Encryption", hint: "Cross-signing, recovery and key backup" },
  { href: "/matrix/settings/safety", title: "Safety", hint: "Ignored users and media previews" },
  { href: "/matrix/settings/devices", title: "Devices", hint: "Where this account is signed in" },
  { href: "/matrix/settings/password", title: "Change Password", hint: "When the homeserver owns it" },
  { href: "/matrix/settings/logout", title: "Log Out", hint: "End this session on this device" },
  { href: "/matrix/settings/deactivate", title: "Deactivate Account", hint: "Close the account for good" },
]

export default function MatrixSettings({
  account,
  device,
}: {
  account: {
    userId: string | null
    deviceId: string | null
    homeserver: string | null
    displayName: string | null
    avatarUrl: string | null
  }
  device: { syncing: boolean; keysPublished: boolean; otkCount: number }
}) {
  const name = account.displayName ?? account.userId ?? "Not configured"

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title="Matrix settings" />

      <ShellHeader>
        <h1 className="text-sm font-medium">Settings</h1>
      </ShellHeader>

      <ScrollArea className="min-h-0 flex-1">
        <div className="mx-auto flex w-full max-w-2xl flex-col gap-4 p-6">
          {!account.userId && (
            <Alert variant="warning">
              <AlertTitle>No device configured</AlertTitle>
              <AlertDescription>
                There is no row in matrix_credentials, so this app is not signed in to a
                homeserver yet.
              </AlertDescription>
            </Alert>
          )}

          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Account</CardTitle>
            </CardHeader>
            <CardContent className="flex flex-col gap-4">
              <div className="flex items-center gap-3">
                <Avatar className="size-14">
                  {account.avatarUrl && <AvatarImage src={account.avatarUrl} alt="" />}
                  <AvatarFallback>{name.replace(/^@/, "").charAt(0).toUpperCase()}</AvatarFallback>
                </Avatar>
                <div className="flex min-w-0 flex-col">
                  <span className="truncate font-medium">{name}</span>
                  <code className="truncate font-mono text-xs text-muted-foreground">
                    {account.userId ?? "—"}
                  </code>
                </div>
              </div>

              <Form action="/matrix/settings" method="post" className="flex flex-col gap-3">
                <div className="flex flex-col gap-2">
                  <Label htmlFor="display_name">Display name</Label>
                  <Input
                    id="display_name"
                    name="display_name"
                    defaultValue={account.displayName ?? ""}
                  />
                </div>
                <Button type="submit" className="self-start" disabled={!account.userId}>
                  Save
                </Button>
              </Form>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-sm">This device</CardTitle>
              <CardDescription>
                The server-side device this app syncs and sends as.
              </CardDescription>
            </CardHeader>
            <CardContent className="flex flex-col gap-2 text-sm">
              <div className="flex items-center justify-between gap-4">
                <span className="text-muted-foreground">Homeserver</span>
                <code className="truncate font-mono text-xs">{account.homeserver ?? "—"}</code>
              </div>
              <div className="flex items-center justify-between gap-4">
                <span className="text-muted-foreground">Device ID</span>
                <code className="truncate font-mono text-xs">{account.deviceId ?? "—"}</code>
              </div>
              <div className="flex items-center justify-between gap-4">
                <span className="text-muted-foreground">Sync</span>
                <span className="flex items-center gap-1 text-xs">
                  {device.syncing ? (
                    <>
                      <CircleCheck className="size-3.5 text-primary" /> has a cursor
                    </>
                  ) : (
                    <>
                      <CircleX className="size-3.5 text-muted-foreground" /> never synced
                    </>
                  )}
                </span>
              </div>
              <div className="flex items-center justify-between gap-4">
                <span className="text-muted-foreground">One-time keys</span>
                {/* A device that runs out stops being reachable for new
                    sessions, silently -- so the number is worth surfacing. */}
                <span className="tabular-nums text-xs">{device.otkCount}</span>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-sm">More</CardTitle>
            </CardHeader>
            <CardContent className="flex flex-col gap-1">
              {SECTIONS.map((section) => (
                <Item key={section.href} render={<Link href={section.href} />}>
<ItemContent>
                      <ItemTitle>{section.title}</ItemTitle>
                      <ItemDescription>{section.hint}</ItemDescription>
                    </ItemContent>
                  </Item>
              ))}
            </CardContent>
          </Card>
        </div>
      </ScrollArea>
    </div>
  )
}
