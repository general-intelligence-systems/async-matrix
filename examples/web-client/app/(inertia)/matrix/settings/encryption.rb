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

  render(
    "matrix/settings/encryption",
    crossSigning: {
      present:  !identity.nil?,
      master:   identity&.cross_signed? || false,
      verified: identity&.verified || false,
    },
    recovery:     {
      configured: Models::Matrix::SecretsInbox
        .named(Models::Matrix::SecretsInbox::MEGOLM_BACKUP).any?,
    },
    # Unverified sessions are the thing worth shouting about: each one can read
    # everything sent to this account.
    unverified:   own_devices.exclude(trust_state: Models::Matrix::Device::VERIFIED).count,
    backedUp:     Models::Matrix::MegolmInboundSession.where(backed_up: true).count,
    total:        Models::Matrix::MegolmInboundSession.count,
  )
end

post "/" do
  halt(501, "matrix: not implemented\n")
end

__END__

import { Head, Link } from "@inertiajs/react"
import { ArrowLeft, KeyRound, ShieldAlert, ShieldCheck } from "lucide-react"

import { Alert, AlertDescription, AlertTitle } from "@/components/reui/alert"
import { Badge } from "@/components/reui/badge"
import { Button } from "@/components/ui/button"
import { Item, ItemContent, ItemTitle } from "@/components/ui/item"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Progress } from "@/components/ui/progress"
import { ScrollArea } from "@/components/ui/scroll-area"
import { ShellHeader } from "@/components/admin/slots"

export default function MatrixSettingsEncryption({
  crossSigning,
  recovery,
  unverified,
  backedUp,
  total,
}: {
  crossSigning: { present: boolean; master: boolean; verified: boolean }
  recovery: { configured: boolean }
  unverified: number
  backedUp: number
  total: number
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
              {!crossSigning.present && (
                <Button size="sm" className="self-start">
                  Set up cross-signing
                </Button>
              )}
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-sm">
                <KeyRound className="size-4" />
                Account Recovery
              </CardTitle>
              <CardDescription>
                {/* Losing this loses every message ever encrypted to this
                    device -- the pickle key is not recoverable from anywhere. */}
                A recovery key restores your message history on a new device. There is no way
                back without it.
              </CardDescription>
            </CardHeader>
            <CardContent className="flex flex-col gap-3">
              <div className="flex items-center justify-between gap-4 text-sm">
                <span className="text-muted-foreground">Recovery key</span>
                <Badge variant={recovery.configured ? "primary" : "secondary"} size="sm">
                  {recovery.configured ? "Stored" : "Not set"}
                </Badge>
              </div>
              <div className="flex gap-2">
                <Button size="sm" variant={recovery.configured ? "outline" : "default"}>
                  {recovery.configured ? "Change recovery key" : "Set up recovery"}
                </Button>
                {recovery.configured && (
                  <Button size="sm" variant="ghost">
                    Reveal
                  </Button>
                )}
              </div>

              <div className="flex items-center justify-between gap-4 border-t pt-3 text-sm">
                <span className="text-muted-foreground">Room keys backed up</span>
                <span className="tabular-nums">
                  {backedUp} / {total}
                </span>
              </div>
              <Progress value={percent} />
            </CardContent>
          </Card>

          {/* Fractal has no separate backup group: the backup is what Account Recovery sets up,
              so its progress is reported there and this group is the two key transfer rows. */}
          <Card>
            <CardContent className="flex flex-col gap-1 pt-6">
              <Item render={<Link href="/matrix/settings/encryption/keys?action=export" />}>
                <ItemContent>
                  <ItemTitle>Export Room Encryption Keys</ItemTitle>
                </ItemContent>
              </Item>
              <Item render={<Link href="/matrix/settings/encryption/keys?action=import" />}>
                <ItemContent>
                  <ItemTitle>Import Room Encryption Keys</ItemTitle>
                </ItemContent>
              </Item>
            </CardContent>
          </Card>
        </div>
      </ScrollArea>
    </div>
  )
}
