# frozen_string_literal: true

# /matrix/login/setup — Session setup
#
# Fractal: login/session_setup_view.{blp,rs}
#
# NOT IMPLEMENTED.
#
# The first screen after a session exists but before it is usable: the device has keys to publish and an identity to verify or bootstrap.
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
# login/session_setup_view.blp
#
#   <Adw.NavigationPage id="SessionSetupView">
#     <Gtk.Stack id="stack" slot="child">
#       <Gtk.StackPage>
#         <Adw.ToolbarView slot="child">
#           <Adw.HeaderBar>
#             <Adw.WindowTitle slot="title-widget" />
#           </Adw.HeaderBar>
#           <Gtk.Box slot="content">
#             <OfflineBanner />
#             <Gtk.Box>
#               <Adw.Spinner />
#               <Gtk.Label />
#             </Gtk.Box>
#           </Gtk.Box>
#         </Adw.ToolbarView>
#       </Gtk.StackPage>
#     </Gtk.Stack>
#   </Adw.NavigationPage>
#

get "/" do
  credential = Models::Matrix::Credential.first

  unless credential&.usable?
    redirect("/matrix/login", 303)
  end

  state = Models::Matrix::DeviceState.first

  render(
    "matrix/login/setup",
    account: {
      userId:   credential.matrix_user_id,
      deviceId: credential.device_id,
    },
    device:  {
      keysPublished: state&.keys_published || false,
    },
  )
end

__END__

import { Head, Link } from "@inertiajs/react"
import { Loader2 } from "lucide-react"

import { Button } from "@/components/ui/button"

export default function MatrixLoginSetup({
  account,
  device,
}: {
  account: { userId: string; deviceId: string }
  device: { keysPublished: boolean }
}) {
  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title="Session Setup" />

      <div className="mx-auto flex w-full max-w-md flex-col items-center gap-6 p-6 pt-16">
        <Loader2 className="size-6 animate-spin text-muted-foreground" />

        <div className="flex flex-col items-center gap-2 text-center">
          <h1 className="text-xl font-semibold tracking-tight">Session Setup</h1>
          <p className="text-sm text-muted-foreground">Fetching Account Data…</p>
        </div>

        <dl className="w-full space-y-1 text-xs text-muted-foreground">
          <div className="flex justify-between gap-4">
            <dt>User</dt>
            <dd className="font-mono">{account.userId}</dd>
          </div>
          <div className="flex justify-between gap-4">
            <dt>Device</dt>
            <dd className="font-mono">{account.deviceId}</dd>
          </div>
          <div className="flex justify-between gap-4">
            <dt>Keys published</dt>
            <dd className="font-mono">{String(device.keysPublished)}</dd>
          </div>
        </dl>

        <Button render={<Link href="/matrix" />} className="w-full">
          Continue
        </Button>
      </div>
    </div>
  )
}
