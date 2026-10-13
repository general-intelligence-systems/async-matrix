# frozen_string_literal: true

# /matrix/settings/encryption — Encryption
#
# Fractal: account_settings/encryption_page/
#
# NOT IMPLEMENTED.
#
# Cross-signing and recovery: SessionSecurity's crypto_identity_state,
# verification_state and recovery_state, over matrix_user_identities and
# matrix_secrets_inbox.
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
# account_settings/encryption_page/mod.blp
#
#   <Adw.PreferencesPage id="EncryptionPage">
#     <Adw.PreferencesGroup>
#       <Adw.PreferencesRow id="crypto_identity_row">
#         <Gtk.Box slot="child">
#           <Gtk.Image id="crypto_identity_icon" />
#           <Gtk.Label id="crypto_identity_title" />
#           <Gtk.Label id="crypto_identity_description" />
#           <Gtk.Button id="crypto_identity_btn" />
#         </Gtk.Box>
#       </Adw.PreferencesRow>
#     </Adw.PreferencesGroup>
#     <Adw.PreferencesGroup>
#       <Adw.PreferencesRow id="recovery_row">
#         <Gtk.Box slot="child">
#           <Gtk.Image id="recovery_icon" />
#           <Gtk.Label id="recovery_title" />
#           <Gtk.Label id="recovery_description" />
#           <Gtk.Button id="recovery_btn" />
#         </Gtk.Box>
#       </Adw.PreferencesRow>
#       <Gtk.ListBox>
#         <Adw.ButtonRow />
#         <Adw.ButtonRow />
#       </Gtk.ListBox>
#     </Adw.PreferencesGroup>
#   </Adw.PreferencesPage>
#
# account_settings/encryption_page/import_export_keys_subpage.blp
#
#   <Adw.NavigationPage id="ImportExportKeysSubpage">
#     <Adw.ToolbarView slot="child">
#       <Adw.HeaderBar />
#       <Gtk.ScrolledWindow slot="content" id="scrolled_window">
#         <Adw.Clamp slot="child">
#           <Gtk.Box slot="child" id="box">
#             <Gtk.Box>
#               <Gtk.Label id="description" />
#               <Gtk.Label id="instructions" />
#             </Gtk.Box>
#             <Gtk.Box>
#               <Gtk.ListBox>
#                 <Adw.PasswordEntryRow id="passphrase" />
#               </Gtk.ListBox>
#               <Gtk.Box id="confirm_passphrase_box">
#                 <Gtk.ListBox>
#                   <Adw.PasswordEntryRow id="confirm_passphrase" />
#                 </Gtk.ListBox>
#                 <Gtk.Revealer id="confirm_passphrase_error_revealer">
#                   <Gtk.Label slot="child" id="confirm_passphrase_error" />
#                 </Gtk.Revealer>
#               </Gtk.Box>
#             </Gtk.Box>
#             <Gtk.ListBox>
#               <Adw.ActionRow id="file_row">
#                 <Gtk.Button id="file_button" />
#               </Adw.ActionRow>
#             </Gtk.ListBox>
#             <Gtk.ListBox>
#               <LoadingButtonRow id="proceed_button" />
#             </Gtk.ListBox>
#           </Gtk.Box>
#         </Adw.Clamp>
#       </Gtk.ScrolledWindow>
#     </Adw.ToolbarView>
#   </Adw.NavigationPage>
#
# components/crypto/identity_setup_view.blp
#
#   <Adw.Bin id="CryptoIdentitySetupView">
#     <Adw.NavigationView slot="child" id="navigation">
#       <Adw.NavigationPage>
#         <Adw.ToolbarView slot="child">
#           <Adw.HeaderBar />
#           <Gtk.ScrolledWindow slot="content">
#             <Adw.Clamp slot="child">
#               <Gtk.Box slot="child">
#                 <Gtk.Label />
#                 <Gtk.Label />
#                 <LoadingButton id="send_request_btn" />
#                 <Gtk.Label />
#                 <Gtk.Button id="use_recovery_btn" />
#                 <Gtk.Button />
#               </Gtk.Box>
#             </Adw.Clamp>
#           </Gtk.ScrolledWindow>
#         </Adw.ToolbarView>
#       </Adw.NavigationPage>
#       <Adw.NavigationPage>
#         <Adw.ToolbarView slot="child">
#           <Adw.HeaderBar />
#           <IdentityVerificationView slot="content" id="verification_page" />
#         </Adw.ToolbarView>
#       </Adw.NavigationPage>
#       <Adw.NavigationPage>
#         <Adw.ToolbarView slot="child">
#           <Adw.HeaderBar />
#           <Gtk.ScrolledWindow slot="content">
#             <Adw.Clamp slot="child">
#               <Gtk.Box slot="child">
#                 <Gtk.Label />
#                 <Gtk.Label />
#                 <Gtk.Label />
#                 <LoadingButton id="bootstrap_btn" />
#               </Gtk.Box>
#             </Adw.Clamp>
#           </Gtk.ScrolledWindow>
#         </Adw.ToolbarView>
#       </Adw.NavigationPage>
#       <Adw.NavigationPage>
#         <Adw.ToolbarView slot="child">
#           <Adw.HeaderBar />
#           <Gtk.ScrolledWindow slot="content">
#             <Adw.Clamp slot="child">
#               <Gtk.Box slot="child">
#                 <Gtk.Label />
#                 <Gtk.Label />
#                 <Gtk.Label />
#                 <Gtk.Label />
#                 <Gtk.Button id="reset_btn" />
#               </Gtk.Box>
#             </Adw.Clamp>
#           </Gtk.ScrolledWindow>
#         </Adw.ToolbarView>
#       </Adw.NavigationPage>
#     </Adw.NavigationView>
#   </Adw.Bin>
#
# components/crypto/recovery_setup_view.blp
#
#   <Adw.Bin id="CryptoRecoverySetupView">
#     <Adw.NavigationView slot="child" id="navigation">
#       <Adw.NavigationPage>
#         <Adw.ToolbarView slot="child">
#           <Adw.HeaderBar />
#           <Gtk.ScrolledWindow slot="content">
#             <Adw.Clamp slot="child">
#               <Gtk.Box slot="child">
#                 <Gtk.Label />
#                 <Gtk.Label />
#                 <Gtk.Label />
#                 <Gtk.ListBox>
#                   <Adw.PasswordEntryRow id="recover_entry" />
#                 </Gtk.ListBox>
#                 <LoadingButton id="recover_btn" />
#                 <Gtk.Label />
#                 <Gtk.Button />
#               </Gtk.Box>
#             </Adw.Clamp>
#           </Gtk.ScrolledWindow>
#         </Adw.ToolbarView>
#       </Adw.NavigationPage>
#       <Adw.NavigationPage id="reset_page">
#         <Adw.ToolbarView slot="child">
#           <Adw.HeaderBar />
#           <Gtk.ScrolledWindow slot="content">
#             <Adw.Clamp slot="child">
#               <Gtk.Box slot="child">
#                 <Gtk.Label />
#                 <Gtk.Label />
#                 <Gtk.ListBox>
#                   <SwitchLoadingRow id="reset_identity_row" />
#                   <SwitchLoadingRow id="reset_backup_row" />
#                 </Gtk.ListBox>
#                 <Gtk.Label />
#                 <Gtk.Label />
#                 <Gtk.ListBox>
#                   <Adw.PasswordEntryRow id="reset_entry" />
#                 </Gtk.ListBox>
#                 <LoadingButton id="reset_btn" />
#               </Gtk.Box>
#             </Adw.Clamp>
#           </Gtk.ScrolledWindow>
#         </Adw.ToolbarView>
#       </Adw.NavigationPage>
#       <Adw.NavigationPage>
#         <Adw.ToolbarView slot="child">
#           <Adw.HeaderBar />
#           <Gtk.ScrolledWindow slot="content">
#             <Adw.Clamp slot="child">
#               <Gtk.Box slot="child">
#                 <Gtk.Label />
#                 <Gtk.Label />
#                 <Gtk.Label />
#                 <Gtk.Label />
#                 <Gtk.ListBox>
#                   <Adw.PasswordEntryRow id="enable_entry" />
#                 </Gtk.ListBox>
#                 <LoadingButton id="enable_btn" />
#               </Gtk.Box>
#             </Adw.Clamp>
#           </Gtk.ScrolledWindow>
#         </Adw.ToolbarView>
#       </Adw.NavigationPage>
#       <Adw.NavigationPage>
#         <Adw.ToolbarView slot="child">
#           <Adw.HeaderBar />
#           <Gtk.ScrolledWindow slot="content">
#             <Adw.Clamp slot="child">
#               <Gtk.Box slot="child">
#                 <Gtk.Label />
#                 <Gtk.Label id="success_description" />
#                 <Gtk.Box id="success_key_box">
#                   <Gtk.Label id="success_key_label" />
#                   <Gtk.Button id="success_key_copy_btn" />
#                 </Gtk.Box>
#                 <Gtk.Button id="success_confirm_btn" />
#               </Gtk.Box>
#             </Adw.Clamp>
#           </Gtk.ScrolledWindow>
#         </Adw.ToolbarView>
#       </Adw.NavigationPage>
#       <Adw.NavigationPage>
#         <Adw.ToolbarView slot="child">
#           <Adw.HeaderBar />
#           <Gtk.ScrolledWindow slot="content">
#             <Adw.Clamp slot="child">
#               <Gtk.Box slot="child">
#                 <Gtk.Label />
#                 <Gtk.Label />
#                 <Gtk.Label />
#                 <Gtk.Label />
#                 <Gtk.Button id="incomplete_confirm_btn" />
#                 <Gtk.Label />
#                 <Gtk.Button />
#               </Gtk.Box>
#             </Adw.Clamp>
#           </Gtk.ScrolledWindow>
#         </Adw.ToolbarView>
#       </Adw.NavigationPage>
#     </Adw.NavigationView>
#   </Adw.Bin>
#
# ── Build with ─────────────────────────────────────────────────────────────
#
# @reui/profile-10 — "Developer API keys page with masked token copy, roll and revoke".
#   A recovery key is a secret you reveal once, copy, and rotate -- the same three
#   affordances. reui/stepper (vendored) drives the setup flows.
#
#   RecoverySetupView                  ->  reui/stepper — already vendored
#   IdentitySetupView (cross-signing)  ->  reui/stepper
#   recovery key display               ->  profile-10's masked reveal + copy
#   RecoveryState (4 values)           ->  reui/alert — Enabled / Disabled / Incomplete / Unknown
#   CryptoIdentityState                ->  ui/badge
#   ImportExportKeysSubpage            ->  ui/dialog + file-upload, passphrase-protected
#   backup_enabled                     ->  ui/switch + ui/progress while keys download
#
# INSTALL, NOT IN EITHER REGISTRY -- reui lists file-upload on its components page but the
#   base-vega registry does not carry it; check the name before relying on it.
#

get "/" do
  credential = Models::Matrix::Credential.first
  identity = Models::Matrix::UserIdentity.first(matrix_user_id: credential&.matrix_user_id)
  own_devices = Models::Matrix::Device.of_user(credential&.matrix_user_id).live
  status = Matrix::Crypto.status

  render(
    "matrix/settings/encryption",
    crossSigning: {
      present:  !identity.nil?,
      master:   identity&.cross_signed? || false,
      verified: identity&.verified || false,
    },
    recovery:     {
      configured: status[:recovery],
      passphrase: Matrix::Crypto.passphrase?,
      missing:    status[:missing],
    },
    backup:       {
      version: status[:backup],
      key:     status[:key],
    },
    # Unverified sessions are the thing worth shouting about: each one can read
    # everything sent to this account.
    unverified:   own_devices.exclude(trust_state: Models::Matrix::Device::VERIFIED).count,
    backedUp:     status[:backup].to_s.empty? ? 0 : status[:sessions],
    total:        status[:sessions],
    fingerprint:  Matrix::Device.fingerprint,
    published:    status[:published],
    error:        session.delete(:matrix_crypto_error),
    flash:        session.delete(:matrix_crypto_flash),
  )
end

post "/" do
  case params["action"].to_s
  in "publish"
    Matrix::Crypto.with_client do |client, _credential|
      Matrix::Device.publish_keys!(client)
    end

    session[:matrix_crypto_flash] = "This session's keys are published."
  in "backup"
    session[:matrix_crypto_flash] = "Backup version #{Matrix::Crypto.ensure_backup!}."
  in "back_up_keys"
    session[:matrix_crypto_flash] = "Backed up #{Matrix::Crypto.back_up_keys!} room keys."
  in "restore"
    session[:matrix_crypto_flash] = "Restored #{Matrix::Crypto.restore_backup!} room keys."
  in "delete_backup"
    Matrix::Crypto.delete_backup!
    session[:matrix_crypto_flash] = "The backup is deleted."
  in "disable_recovery"
    Matrix::Crypto.disable_recovery!
    session[:matrix_crypto_flash] = "Account recovery is off."
  else
    halt(400, "matrix: no such action\n")
  end

  redirect("/matrix/settings/encryption", 303)
rescue Matrix::RoomActions::Error => error
  session[:matrix_crypto_error] = error.message
  redirect("/matrix/settings/encryption", 303)
rescue Async::Matrix::RequestError => error
  session[:matrix_crypto_error] = error.message
  redirect("/matrix/settings/encryption", 303)
end

__END__

import { Form, Head, Link } from "@inertiajs/react"
import { ArrowLeft, KeyRound, ShieldAlert, ShieldCheck } from "lucide-react"

import { Alert, AlertDescription, AlertTitle } from "@/components/reui/alert"
import { Badge } from "@/components/reui/badge"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Item, ItemContent, ItemDescription, ItemTitle } from "@/components/ui/item"
import { Progress } from "@/components/ui/progress"
import { ScrollArea } from "@/components/ui/scroll-area"
import { ShellHeader } from "@/components/admin/slots"

function Action({
  action,
  children,
  variant,
  disabled,
}: {
  action: string
  children: React.ReactNode
  variant?: "default" | "outline" | "destructive"
  disabled?: boolean
}) {
  return (
    <Form action="/matrix/settings/encryption" method="post">
      {({ processing }) => (
        <>
          <input type="hidden" name="action" value={action} />
          <Button type="submit" size="sm" variant={variant} disabled={processing || disabled}>
            {children}
          </Button>
        </>
      )}
    </Form>
  )
}

export default function MatrixSettingsEncryption({
  crossSigning,
  recovery,
  backup,
  unverified,
  backedUp,
  total,
  fingerprint,
  published,
  error,
  flash,
}: {
  crossSigning: { present: boolean; master: boolean; verified: boolean }
  recovery: { configured: boolean; passphrase: boolean; missing: string[] }
  backup: { version: string | null; key: boolean }
  unverified: number
  backedUp: number
  total: number
  fingerprint: string
  published: boolean
  error: string | null
  flash: string | null
}) {
  const percent = total > 0 ? Math.round((backedUp / total) * 100) : 0

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title="Encryption · matrix" />

      <ShellHeader>
        <Link href="/matrix/settings" className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="text-sm font-medium">Encryption</h1>
      </ShellHeader>

      <ScrollArea className="min-h-0 flex-1">
        <div className="mx-auto flex w-full max-w-2xl flex-col gap-4 p-6">
          {error ? (
            <Alert variant="destructive">
              <AlertTitle>It did not go through</AlertTitle>
              <AlertDescription>{error}</AlertDescription>
            </Alert>
          ) : null}

          {flash ? (
            <Alert>
              <AlertTitle>{flash}</AlertTitle>
            </Alert>
          ) : null}

          {unverified > 0 && (
            <Alert variant="destructive">
              <AlertTitle>
                {unverified} unverified {unverified === 1 ? "session" : "sessions"}
              </AlertTitle>
              <AlertDescription>
                Each one can read everything sent to this account. Verify or sign them out.{" "}
                <Link href="/matrix/settings/devices" className="underline">
                  Review devices
                </Link>
              </AlertDescription>
            </Alert>
          )}

          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-sm">
                {crossSigning.verified ? (
                  <ShieldCheck className="size-4 text-primary" />
                ) : (
                  <ShieldAlert className="size-4 text-muted-foreground" />
                )}
                Crypto Identity
              </CardTitle>
              <CardDescription>
                How other people's clients know a device is really yours.
              </CardDescription>
            </CardHeader>
            <CardContent className="flex flex-col gap-3">
              <div className="flex items-center justify-between gap-4 text-sm">
                <span className="text-muted-foreground">Identity</span>
                <Badge variant={crossSigning.present ? "primary" : "secondary"} size="sm">
                  {crossSigning.present ? "Set up" : "Not set up"}
                </Badge>
              </div>
              <div className="flex items-center justify-between gap-4 text-sm">
                <span className="text-muted-foreground">This session</span>
                <Badge variant={crossSigning.verified ? "primary" : "destructive"} size="sm">
                  {crossSigning.verified ? "Verified" : "Unverified"}
                </Badge>
              </div>
              <div className="flex items-center justify-between gap-4 text-sm">
                <span className="text-muted-foreground">Session key</span>
                <code className="font-mono text-xs break-all">{fingerprint || "none"}</code>
              </div>
              <div className="flex flex-wrap items-center gap-2">
                <Button
                  size="sm"
                  variant={crossSigning.present ? "outline" : "default"}
                  render={<Link href="/matrix/settings/encryption/identity" />}
                >
                  {crossSigning.present ? "Manage identity" : "Set up cross-signing"}
                </Button>
                {!published && <Action action="publish">Publish this session's keys</Action>}
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-sm">
                <KeyRound className="size-4" />
                Account Recovery
              </CardTitle>
              <CardDescription>
                Secret storage, which is what a new session reads the keys back from.
              </CardDescription>
            </CardHeader>
            <CardContent className="flex flex-col gap-3">
              <div className="flex items-center justify-between gap-4 text-sm">
                <span className="text-muted-foreground">Recovery</span>
                <Badge variant={recovery.configured ? "primary" : "secondary"} size="sm">
                  {recovery.configured
                    ? recovery.passphrase
                      ? "Passphrase"
                      : "Recovery key"
                    : "Not set up"}
                </Badge>
              </div>
              {recovery.missing.length > 0 && (
                <Alert variant="warning">
                  <AlertTitle>Account Recovery Incomplete</AlertTitle>
                  <AlertDescription>
                    {recovery.missing.length} of 4 secrets are missing.{" "}
                    <Link href="/matrix/settings/encryption/recovery/incomplete" className="underline">
                      See what
                    </Link>
                  </AlertDescription>
                </Alert>
              )}
              <div className="flex flex-wrap items-center gap-2">
                {recovery.configured ? (
                  <>
                    <Button size="sm" variant="outline" render={<Link href="/matrix/settings/encryption/recovery" />}>
                      Recover Account
                    </Button>
                    <Button size="sm" variant="outline" render={<Link href="/matrix/settings/encryption/recovery/reset" />}>
                      Reset
                    </Button>
                    <Action action="disable_recovery" variant="destructive">
                      Turn off
                    </Action>
                  </>
                ) : (
                  <Button size="sm" render={<Link href="/matrix/settings/encryption/recovery/enable" />}>
                    Set Up
                  </Button>
                )}
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Key Backup</CardTitle>
              <CardDescription>
                {backup.version
                  ? `Version ${backup.version} on the homeserver.`
                  : "No backup exists, so nothing is kept for a new session."}
              </CardDescription>
            </CardHeader>
            <CardContent className="flex flex-col gap-3">
              <div className="flex items-center justify-between gap-4 text-sm">
                <span className="text-muted-foreground">Room keys held here</span>
                <span>{total}</span>
              </div>
              <Progress value={percent} />
              <p className="text-xs text-muted-foreground">
                {backedUp} of {total} backed up.
              </p>
              <div className="flex flex-wrap items-center gap-2">
                {backup.version ? (
                  <>
                    <Action action="back_up_keys" disabled={total === 0 || !backup.key}>
                      Back up now
                    </Action>
                    <Action action="restore" variant="outline" disabled={!backup.key}>
                      Restore from backup
                    </Action>
                    <Action action="delete_backup" variant="destructive">
                      Delete backup
                    </Action>
                  </>
                ) : (
                  <Action action="backup">Create a backup</Action>
                )}
              </div>
              {backup.version && !backup.key && (
                <Alert variant="warning">
                  <AlertTitle>This session does not hold the backup key</AlertTitle>
                  <AlertDescription>
                    Recover the account, or verify against a session that has it.
                  </AlertDescription>
                </Alert>
              )}
            </CardContent>
          </Card>

          <Item variant="outline">
            <ItemContent>
              <ItemTitle>Import and export keys</ItemTitle>
              <ItemDescription>
                Room keys as a passphrase-encrypted file, which is the manual alternative to
                recovery.
              </ItemDescription>
            </ItemContent>
            <Button size="sm" variant="outline" render={<Link href="/matrix/settings/encryption/keys" />}>
              Open
            </Button>
          </Item>
        </div>
      </ScrollArea>
    </div>
  )
}
