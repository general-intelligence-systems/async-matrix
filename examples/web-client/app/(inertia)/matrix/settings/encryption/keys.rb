# frozen_string_literal: true

# /matrix/settings/encryption/keys — Import and export keys
#
# Fractal: account_settings/encryption_page/import_export_keys_subpage.{blp,rs}
#
# Room keys as a passphrase-encrypted file, which is the manual alternative to recovery: the export is every megolm inbound session this device holds.
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
# account_settings/encryption_page/import_export_keys_subpage.blp
#
#   <Adw.NavigationPage id="ImportExportKeysSubpage">
#     <Adw.ToolbarView slot="child">
#       <Adw.HeaderBar />
#       <Gtk.ScrolledWindow id="scrolled_window" slot="content">
#         <Adw.Clamp slot="child">
#           <Gtk.Box id="box" slot="child">
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
#                   <Gtk.Label id="confirm_passphrase_error" slot="child" />
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

get "/" do
  render(
    "matrix/settings/encryption/keys",
    status:   Matrix::Crypto.status,
    imported: session.delete(:matrix_keys_imported),
    error:    session.delete(:matrix_crypto_error),
  )
end

post "/" do
  passphrase = params["passphrase"].to_s

  if passphrase.empty?
    session[:matrix_crypto_error] = "a passphrase is needed to read or write an export"
    redirect("/matrix/settings/encryption/keys", 303)
  end

  case params["action"].to_s
  in "export"
    confirm = params["confirm_passphrase"].to_s

    unless passphrase == confirm
      session[:matrix_crypto_error] = "Passphrases do not match"
      redirect("/matrix/settings/encryption/keys", 303)
    end

    content_type("text/plain")
    headers("content-disposition" => "attachment; filename=\"element-keys.txt\"")

    Matrix::Crypto.export_keys(passphrase)
  in "import"
    upload = params["file"]

    if upload.nil?
      session[:matrix_crypto_error] = "no file was chosen"
      redirect("/matrix/settings/encryption/keys", 303)
    end

    session[:matrix_keys_imported] = Matrix::Crypto.import_keys(
      upload[:tempfile].read, passphrase,
    )

    redirect("/matrix/settings/encryption/keys", 303)
  else
    halt(400, "matrix: no such action\n")
  end
rescue Matrix::RoomActions::Error => error
  session[:matrix_crypto_error] = error.message
  redirect("/matrix/settings/encryption/keys", 303)
end

__END__

import { Head, Link } from "@inertiajs/react"
import { ArrowLeft, Download, Upload } from "lucide-react"

import { Alert, AlertDescription, AlertTitle } from "@/components/reui/alert"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Field, FieldDescription, FieldGroup, FieldLabel } from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import { ShellHeader } from "@/components/admin/slots"

export default function MatrixSettingsEncryptionKeys({
  status,
  imported,
  error,
}: {
  status: { sessions: number; backup: string | null; key: boolean }
  imported: number | null
  error: string | null
}) {
  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title="Import and export keys" />

      <ShellHeader>
        <Link href="/matrix/settings/encryption" className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">Import and export keys</h1>
      </ShellHeader>

      <div className="mx-auto flex w-full max-w-xl flex-col gap-4 p-6">
        {error ? (
          <Alert variant="destructive">
            <AlertTitle>It did not go through</AlertTitle>
            <AlertDescription>{error}</AlertDescription>
          </Alert>
        ) : null}

        {imported !== null && imported !== undefined ? (
          <Alert>
            <AlertTitle>
              Imported {imported} room {imported === 1 ? "key" : "keys"}
            </AlertTitle>
            <AlertDescription>
              Messages they cover can be read again from the moment each key starts.
            </AlertDescription>
          </Alert>
        ) : null}

        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-sm">
              <Download className="size-4" />
              Export room keys
            </CardTitle>
            <CardDescription>
              This session holds {status.sessions} room {status.sessions === 1 ? "key" : "keys"}. The
              file is encrypted with the passphrase and nothing else.
            </CardDescription>
          </CardHeader>
          <CardContent>
            <form
              action="/matrix/settings/encryption/keys"
              method="post"
              className="flex flex-col gap-4"
            >
              <input type="hidden" name="action" value="export" />
              <FieldGroup>
                <Field>
                  <FieldLabel htmlFor="export_passphrase">Passphrase</FieldLabel>
                  <Input
                    id="export_passphrase"
                    name="passphrase"
                    type="password"
                    autoComplete="new-password"
                    required
                  />
                  <FieldDescription>
                    It is the only thing that opens the file, so it cannot be recovered.
                  </FieldDescription>
                </Field>
                <Field>
                  <FieldLabel htmlFor="export_confirm">Confirm passphrase</FieldLabel>
                  <Input
                    id="export_confirm"
                    name="confirm_passphrase"
                    type="password"
                    autoComplete="new-password"
                    required
                  />
                </Field>
              </FieldGroup>
              <Button type="submit" className="self-start" disabled={status.sessions === 0}>
                Export
              </Button>
            </form>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-sm">
              <Upload className="size-4" />
              Import room keys
            </CardTitle>
            <CardDescription>A file another client exported, with its passphrase.</CardDescription>
          </CardHeader>
          <CardContent>
            <form
              action="/matrix/settings/encryption/keys"
              method="post"
              encType="multipart/form-data"
              className="flex flex-col gap-4"
            >
              <input type="hidden" name="action" value="import" />
              <FieldGroup>
                <Field>
                  <FieldLabel htmlFor="file">File</FieldLabel>
                  <Input id="file" name="file" type="file" required />
                </Field>
                <Field>
                  <FieldLabel htmlFor="import_passphrase">Passphrase</FieldLabel>
                  <Input
                    id="import_passphrase"
                    name="passphrase"
                    type="password"
                    autoComplete="off"
                    required
                  />
                </Field>
              </FieldGroup>
              <Button type="submit" variant="outline" className="self-start">
                Import
              </Button>
            </form>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
