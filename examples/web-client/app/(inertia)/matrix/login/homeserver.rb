# frozen_string_literal: true

# /matrix/login/homeserver — Homeserver
#
# Fractal: login/homeserver_page.{blp,rs}
#
# NOT IMPLEMENTED.
#
# Which homeserver to log in to, and what it supports: the well-known lookup and the login flows it advertises decide whether the next screen is a password form or the browser.
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
# login/homeserver_page.blp
#
#   <Adw.NavigationPage id="LoginHomeserverPage">
#     <Adw.ToolbarView slot="child">
#       <Adw.HeaderBar />
#       <Gtk.Box slot="content">
#         <OfflineBanner />
#         <Gtk.ScrolledWindow id="scrolled_window">
#           <Adw.Clamp slot="child">
#             <Gtk.Box slot="child">
#               <Gtk.Label id="title" />
#               <Gtk.Picture />
#               <Gtk.Box>
#                 <Gtk.ListBox>
#                   <Adw.EntryRow id="homeserver_entry" />
#                 </Gtk.ListBox>
#                 <Gtk.Label id="homeserver_help" />
#               </Gtk.Box>
#               <LoadingButton id="next_button" />
#               <Gtk.Button />
#             </Gtk.Box>
#           </Adw.Clamp>
#         </Gtk.ScrolledWindow>
#       </Gtk.Box>
#     </Adw.ToolbarView>
#   </Adw.NavigationPage>
#

get "/" do
  unless params["register"].to_s.empty?
    session[:matrix_register_intent] = true
  end

  render(
    "matrix/login/homeserver",
    autodiscovery: session.fetch(:matrix_autodiscovery, true),
    value:         session[:matrix_homeserver_input].to_s,
    register:      session[:matrix_register_intent] || false,
    error:         session.delete(:matrix_homeserver_error),
  )
end

# Resolve first, then move on: the method page needs the base URL and the flows, and a domain that
# does not answer is this page's error rather than the next page's empty state.
post "/" do
  autodiscovery = params["autodiscovery"].to_s != "false"
  input = params["homeserver"].to_s.strip

  session[:matrix_autodiscovery] = autodiscovery
  session[:matrix_homeserver_input] = input

  base_url = Matrix::Homeserver.resolve(input, autodiscovery: autodiscovery)

  if base_url.nil?
    if autodiscovery
      session[:matrix_homeserver_error] = "that is not a domain name"
    else
      session[:matrix_homeserver_error] = "that is not an http or https URL"
    end

    redirect("/matrix/login/homeserver", 303)
  end

  # Fractal's discover_login_api, in order: the OAuth 2.0 API is preferred, the native API is the
  # fallback, and within the native API a homeserver without m.login.password goes straight to the
  # browser because there is no form to show (login/mod.rs).
  if Matrix::Homeserver.oauth?(base_url)
    session[:matrix_base_url] = base_url
    session[:matrix_auth] = "oauth"
    session[:matrix_flows] = []

    if autodiscovery
      session[:matrix_domain] = input
    else
      session[:matrix_domain] = nil
    end

    redirect("/matrix/login/browser", 303)
  end

  flows = Matrix::Homeserver.login_flows(base_url)

  if flows.empty?
    session[:matrix_homeserver_error] = "no Matrix homeserver answered at #{base_url}"
    redirect("/matrix/login/homeserver", 303)
  end

  session[:matrix_base_url] = base_url
  session[:matrix_auth] = "matrix"
  session[:matrix_flows] = flows

  if autodiscovery
    session[:matrix_domain] = input
  else
    session[:matrix_domain] = nil
  end

  if session.delete(:matrix_register_intent)
    redirect("/matrix/login/register", 303)
  end

  unless flows.include?("m.login.password")
    redirect("/matrix/login/browser", 303)
  end

  redirect("/matrix/login/method", 303)
end

__END__

import { Form, Head, Link } from "@inertiajs/react"
import { ArrowLeft } from "lucide-react"

import { Alert, AlertDescription, AlertTitle } from "@/components/reui/alert"
import { Button } from "@/components/ui/button"
import { Field, FieldDescription, FieldGroup, FieldLabel } from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import { ShellHeader } from "@/components/admin/slots"

export default function MatrixLoginHomeserver({
  autodiscovery,
  value,
  register,
  error,
}: {
  autodiscovery: boolean
  value: string
  register: boolean
  error: string | null
}) {
  // Fractal swaps the entry's own title and help text on the auto-discovery setting, because a
  // domain and a URL are different things to be asked for (homeserver_page.rs update_text).
  const label = autodiscovery ? "Domain Name" : "Homeserver URL"
  const help = autodiscovery
    ? "The domain of your Matrix homeserver, for example gnome.org"
    : "The URL of your Matrix homeserver, for example https://gnome.modular.im"

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title="Homeserver" />

      <ShellHeader>
        <Link href="/matrix/login" className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">Homeserver</h1>
      </ShellHeader>

      <div className="mx-auto flex w-full max-w-md flex-col gap-6 p-6">
        <h2 className="text-xl font-semibold tracking-tight">
          {register ? "Where to create the account" : "Homeserver"}
        </h2>

        {error ? (
          <Alert variant="destructive">
            <AlertTitle>Could not reach it</AlertTitle>
            <AlertDescription>{error}</AlertDescription>
          </Alert>
        ) : null}

        <Form action="/matrix/login/homeserver" method="post" className="flex flex-col gap-4">
          {({ processing }) => (
            <>
              <input type="hidden" name="autodiscovery" value={String(autodiscovery)} />

              <FieldGroup>
                <Field>
                  <FieldLabel htmlFor="homeserver">{label}</FieldLabel>
                  <Input
                    id="homeserver"
                    name="homeserver"
                    defaultValue={value}
                    autoFocus
                    autoCapitalize="none"
                    spellCheck={false}
                    placeholder={autodiscovery ? "gnome.org" : "https://gnome.modular.im"}
                  />
                  <FieldDescription>{help}</FieldDescription>
                </Field>
              </FieldGroup>

              <Button type="submit" disabled={processing} className="self-center">
                Next
              </Button>
            </>
          )}
        </Form>

        <Button
          variant="ghost"
          render={<Link href="/matrix/login/advanced" />}
          className="self-center"
        >
          Advanced…
        </Button>
      </div>
    </div>
  )
}
