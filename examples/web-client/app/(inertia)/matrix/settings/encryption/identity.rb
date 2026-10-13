# frozen_string_literal: true

# /matrix/settings/encryption/identity — Crypto identity
#
# Fractal: components/crypto/identity_setup_view.{blp,rs} (tag choose-method)
#
# How this device joins the account's cross-signing identity: verify against a device that already has it, or bootstrap a new one.
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
# components/crypto/identity_setup_view.blp
#
#   <Adw.NavigationPage>
#     <Adw.ToolbarView slot="child">
#       <Adw.HeaderBar />
#       <Gtk.ScrolledWindow slot="content">
#         <Adw.Clamp slot="child">
#           <Gtk.Box slot="child">
#             <Gtk.Label />
#             <Gtk.Label />
#             <LoadingButton id="send_request_btn" />
#             <Gtk.Label />
#             <Gtk.Button id="use_recovery_btn" />
#             <Gtk.Button />
#           </Gtk.Box>
#         </Adw.Clamp>
#       </Gtk.ScrolledWindow>
#     </Adw.ToolbarView>
#   </Adw.NavigationPage>
#

get "/" do
  render(
    "matrix/settings/encryption/identity",
    status:  Matrix::Crypto.status,
    session: Models::Matrix::Device
      .of_user(Models::Matrix::Credential.first&.matrix_user_id)
      .live
      .exclude(device_id: Models::Matrix::Credential.first&.device_id)
      .count,
  )
end

__END__

import { Head, Link } from "@inertiajs/react"
import { ArrowLeft, KeyRound, MonitorSmartphone } from "lucide-react"

import { Alert, AlertDescription, AlertTitle } from "@/components/reui/alert"
import { Button } from "@/components/ui/button"
import { Item, ItemContent, ItemDescription, ItemTitle } from "@/components/ui/item"
import { ShellHeader } from "@/components/admin/slots"

export default function MatrixSettingsEncryptionIdentity({
  status,
  session,
}: {
  status: { identity: boolean; recovery: boolean; published: boolean; missing: string[] }
  session: number
}) {
  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title="Crypto identity" />

      <ShellHeader>
        <Link href="/matrix/settings/encryption" className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">Verify Your New Session</h1>
      </ShellHeader>

      <div className="mx-auto flex w-full max-w-xl flex-col gap-4 p-6">
        {status.identity ? (
          <Alert>
            <AlertTitle>This account has a crypto identity</AlertTitle>
            <AlertDescription>
              Verify this session against one that already holds the keys, or recover them from
              account recovery.
            </AlertDescription>
          </Alert>
        ) : (
          <Alert variant="warning">
            <AlertTitle>No crypto identity</AlertTitle>
            <AlertDescription>
              You need to set up a crypto identity, since it has never been created.
            </AlertDescription>
          </Alert>
        )}

        {status.identity ? (
          <>
            <Item variant="outline">
              <ItemContent>
                <ItemTitle className="flex items-center gap-2">
                  <MonitorSmartphone className="size-4" />
                  Verify With Another Session
                </ItemTitle>
                <ItemDescription>
                  {session === 0
                    ? "No other session is signed in to answer."
                    : `${session} other ${session === 1 ? "session" : "sessions"} can answer.`}
                </ItemDescription>
              </ItemContent>
              <Button size="sm" disabled={session === 0} render={<Link href="/matrix/settings/encryption/identity/verify" />}>
                Verify
              </Button>
            </Item>

            <Item variant="outline">
              <ItemContent>
                <ItemTitle className="flex items-center gap-2">
                  <KeyRound className="size-4" />
                  Recover Account
                </ItemTitle>
                <ItemDescription>Restore full access to your account.</ItemDescription>
              </ItemContent>
              <Button size="sm" variant="outline" render={<Link href="/matrix/settings/encryption/recovery" />}>
                Recover
              </Button>
            </Item>
          </>
        ) : (
          <Item variant="outline">
            <ItemContent>
              <ItemTitle>Set Up</ItemTitle>
              <ItemDescription>Mint the master, self-signing and user-signing keys.</ItemDescription>
            </ItemContent>
            <Button size="sm" render={<Link href="/matrix/settings/encryption/identity/bootstrap" />}>
              Set Up
            </Button>
          </Item>
        )}

        <Item variant="muted">
          <ItemContent>
            <ItemTitle>Reset Crypto Identity</ItemTitle>
            <ItemDescription>
              Everyone who verified you, and every other session, has to verify again.
            </ItemDescription>
          </ItemContent>
          <Button size="sm" variant="destructive" render={<Link href="/matrix/settings/encryption/identity/reset" />}>
            Reset
          </Button>
        </Item>
      </div>
    </div>
  )
}
