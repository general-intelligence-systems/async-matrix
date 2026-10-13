# frozen_string_literal: true

# /matrix/login/browser — Log in with browser
#
# Fractal: login/in_browser_page.{blp,rs}
#
# NOT IMPLEMENTED.
#
# The holding screen while the OIDC flow runs elsewhere. Fractal opens a browser and waits on a loopback server; here the browser is already the client, so this is where the redirect to MAS is taken.
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
# login/in_browser_page.blp
#
#   <Adw.NavigationPage id="LoginInBrowserPage">
#     <Adw.ToolbarView slot="child">
#       <Adw.HeaderBar />
#       <Gtk.Box slot="content">
#         <OfflineBanner />
#         <Gtk.ScrolledWindow id="scrolled_window">
#           <Adw.Clamp slot="child">
#             <Gtk.Box slot="child">
#               <Gtk.Label id="title" />
#               <Gtk.Label id="instructions" />
#               <Gtk.Button id="continue_btn">
#                 <Gtk.Box slot="child">
#                   <Gtk.Label />
#                   <Gtk.Image />
#                 </Gtk.Box>
#               </Gtk.Button>
#             </Gtk.Box>
#           </Adw.Clamp>
#         </Gtk.ScrolledWindow>
#       </Gtk.Box>
#     </Adw.ToolbarView>
#   </Adw.NavigationPage>
#

get "/" do
  base_url = session[:matrix_base_url].to_s

  if base_url.empty?
    redirect("/matrix/login/homeserver", 303)
  end

  session[:matrix_sso_provider] = params["provider"].to_s

  render(
    "matrix/login/browser",
    homeserver: base_url,
    provider:   params["provider"].to_s,
  )
end

# Fractal opens a browser and waits on a loopback server for the redirect. Here the browser IS the
# client, so "continue" is the redirect itself and the callback route is the loopback.
post "/" do
  base_url = session[:matrix_base_url].to_s

  if base_url.empty?
    redirect("/matrix/login/homeserver", 303)
  end

  redirect(
    Matrix::Homeserver.sso_url(
      base_url,
      "#{request.base_url}/matrix/callback",
      provider: session[:matrix_sso_provider],
    ),
    303,
  )
end

__END__

import { Form, Head, Link } from "@inertiajs/react"
import { ArrowLeft } from "lucide-react"

import { Button } from "@/components/ui/button"
import { ShellHeader } from "@/components/admin/slots"

export default function MatrixLoginBrowser({
  homeserver,
}: {
  homeserver: string
  provider: string
}) {
  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title="Authentication" />

      <ShellHeader>
        <Link href="/matrix/login/method" className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">Authentication</h1>
      </ShellHeader>

      <div className="mx-auto flex w-full max-w-md flex-col items-center gap-6 p-6 pt-12">
        <h2 className="text-xl font-semibold tracking-tight">Authentication</h2>

        <p className="text-center text-sm text-muted-foreground">
          Click on the button below and follow the steps in the browser
        </p>

        <p className="font-mono text-xs text-muted-foreground">{homeserver.replace(/\/$/, "")}</p>

        <Form action="/matrix/login/browser" method="post">
          {({ processing }) => (
            <Button type="submit" disabled={processing}>
              Continue
            </Button>
          )}
        </Form>
      </div>
    </div>
  )
}
