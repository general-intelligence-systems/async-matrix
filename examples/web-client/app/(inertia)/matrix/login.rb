# frozen_string_literal: true

# /matrix/login — Welcome
#
# Fractal: login/greeter.{blp,rs}
#
# The first screen of the login NavigationView, and the only one reachable without a session: the
# gate in matrix/_layout.rb sends everything else here.
#
# It asks nothing. Fractal's greeter is a picture, a welcome and two buttons, because which
# homeserver you are on is the next screen's question and not this one's.
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
# login/greeter.blp
#
#   <Adw.NavigationPage id="Greeter">
#     <Adw.ToolbarView slot="child">
#       <Adw.HeaderBar>
#         <Gtk.Button id="back_button" />
#         <Gtk.Button />
#         <Gtk.Button />
#       </Adw.HeaderBar>
#       <Gtk.Box slot="content">
#         <Gtk.ScrolledWindow>
#           <Gtk.Box slot="child">
#             <Adw.Clamp>
#               <Gtk.Box slot="child">
#                 <Gtk.Picture />
#                 <Gtk.Label id="title" />
#               </Gtk.Box>
#             </Adw.Clamp>
#             <Adw.Clamp>
#               <Gtk.Box slot="child">
#                 <Gtk.Button id="login_button" />
#                 <Gtk.Button />
#               </Gtk.Box>
#             </Adw.Clamp>
#           </Gtk.Box>
#         </Gtk.ScrolledWindow>
#       </Gtk.Box>
#     </Adw.ToolbarView>
#   </Adw.NavigationPage>
#

get "/" do
  credential = Models::Matrix::Credential.first

  render(
    "matrix/login",
    connected: credential&.usable? || false,
    account:   {
      userId:   credential&.matrix_user_id,
      deviceId: credential&.device_id,
    },
    error: session.delete(:matrix_login_error),
  )
end

__END__

import { Head, Link } from "@inertiajs/react"

import { Alert, AlertDescription, AlertTitle } from "@/components/reui/alert"
import { Button } from "@/components/ui/button"

export default function MatrixLogin({
  connected,
  account,
  error,
}: {
  connected: boolean
  account: { userId: string | null; deviceId: string | null }
  error: string | null
}) {
  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title="Welcome" />

      <div className="mx-auto flex w-full max-w-md flex-col items-center gap-8 p-6 pt-16">
        <div className="flex flex-col items-center gap-3 text-center">
          <h1 className="text-2xl font-semibold tracking-tight">Welcome</h1>
          <p className="text-sm text-muted-foreground">
            A Matrix client for one operator and one device.
          </p>
        </div>

        {error ? (
          <Alert variant="destructive" className="w-full">
            <AlertTitle>Could not sign in</AlertTitle>
            <AlertDescription>{error}</AlertDescription>
          </Alert>
        ) : null}

        {connected ? (
          <Alert className="w-full">
            <AlertTitle>Already signed in</AlertTitle>
            <AlertDescription>
              {account.userId} on device {account.deviceId}.
            </AlertDescription>
          </Alert>
        ) : null}

        <div className="flex w-full flex-col gap-2">
          <Button render={<Link href="/matrix/login/homeserver" />} className="w-full">
            Log in
          </Button>
          <Button variant="ghost" disabled className="w-full">
            Create account
          </Button>
        </div>
      </div>
    </div>
  )
}
