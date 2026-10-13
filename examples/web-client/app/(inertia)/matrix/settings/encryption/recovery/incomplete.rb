# frozen_string_literal: true

# /matrix/settings/encryption/recovery/incomplete — Recovery incomplete
#
# Fractal: components/crypto/recovery_setup_view.{blp,rs} (tag incomplete)
#
# Secret storage exists but something it should hold is missing, so recovery would not restore everything.
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
# components/crypto/recovery_setup_view.blp
#
#   <Adw.NavigationPage>
#     <Adw.ToolbarView slot="child">
#       <Adw.HeaderBar />
#       <Gtk.ScrolledWindow slot="content">
#         <Adw.Clamp slot="child">
#           <Gtk.Box slot="child">
#             <Gtk.Label />
#             <Gtk.Label />
#             <Gtk.Label />
#             <Gtk.Label />
#             <Gtk.Button id="incomplete_confirm_btn" />
#             <Gtk.Label />
#             <Gtk.Button />
#           </Gtk.Box>
#         </Adw.Clamp>
#       </Gtk.ScrolledWindow>
#     </Adw.ToolbarView>
#   </Adw.NavigationPage>
#

get "/" do
  render(
    "matrix/settings/encryption/recovery/incomplete",
    status: Matrix::Crypto.status,
  )
end

post "/" do
  act! do
    Matrix::Crypto.write_secrets!
  end
end

__END__

import { Form, Head, Link } from "@inertiajs/react"
import { ArrowLeft, ShieldAlert } from "lucide-react"

import { Alert, AlertDescription, AlertTitle } from "@/components/reui/alert"
import { Button } from "@/components/ui/button"
import { Item, ItemContent, ItemTitle } from "@/components/ui/item"
import { ShellHeader } from "@/components/admin/slots"

const NAMES: Record<string, string> = {
  "m.cross_signing.master": "Master key",
  "m.cross_signing.self_signing": "Self-signing key",
  "m.cross_signing.user_signing": "User-signing key",
  "m.megolm_backup.v1": "Key backup key",
}

export default function MatrixSettingsEncryptionRecoveryIncomplete({
  status,
}: {
  status: { identity: boolean; recovery: boolean; missing: string[]; backup: string | null }
}) {
  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title="Recovery incomplete" />

      <ShellHeader>
        <Link href="/matrix/settings/encryption" className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">Account Recovery Incomplete</h1>
      </ShellHeader>

      <div className="mx-auto flex w-full max-w-xl flex-col gap-4 p-6">
        <div className="flex flex-col items-center gap-2 py-4">
          <ShieldAlert className="size-10 text-muted-foreground" />
          <h2 className="text-center text-xl font-semibold tracking-tight">
            Account Recovery Incomplete
          </h2>
        </div>

        <Alert variant="warning">
          <AlertTitle>Something it should hold is missing</AlertTitle>
          <AlertDescription>
            Recovery exists but does not have everything, so a new session would not get all of it
            back. Writing what this session holds fills the gaps it can.
          </AlertDescription>
        </Alert>

        {status.missing.map((name) => (
          <Item key={name} variant="outline">
            <ItemContent>
              <ItemTitle>{NAMES[name] || name}</ItemTitle>
            </ItemContent>
            <span className="text-xs text-muted-foreground">Missing</span>
          </Item>
        ))}

        {status.missing.length === 0 && (
          <Alert>
            <AlertTitle>Nothing is missing any more</AlertTitle>
            <AlertDescription>This session holds every secret recovery should carry.</AlertDescription>
          </Alert>
        )}

        <Form action="/matrix/settings/encryption/recovery/incomplete" method="post">
          {({ processing }) => (
            <>
              <input type="hidden" name="return_to" value="/matrix/settings/encryption" />
              <Button type="submit" disabled={processing || status.missing.length === 0}>
                Write what this session holds
              </Button>
            </>
          )}
        </Form>
      </div>
    </div>
  )
}
