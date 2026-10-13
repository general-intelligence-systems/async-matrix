# frozen_string_literal: true

# /matrix/login/method — Log in method
#
# Fractal: login/method_page.{blp,rs}
#
# NOT IMPLEMENTED.
#
# The login flows the homeserver advertises, as a choice: a password form when it supports m.login.password, the browser when it is OIDC.
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
# login/method_page.blp
#
#   <Adw.NavigationPage id="LoginMethodPage">
#     <Adw.ToolbarView slot="child">
#       <Adw.HeaderBar />
#       <Gtk.Box slot="content">
#         <OfflineBanner />
#         <Gtk.ScrolledWindow id="scrolled_window">
#           <Adw.Clamp slot="child">
#             <Gtk.Box slot="child">
#               <Gtk.Box>
#                 <Gtk.Label id="title" />
#                 <Gtk.Box>
#                   <Gtk.Image />
#                   <Gtk.Label id="homeserver_url" />
#                 </Gtk.Box>
#               </Gtk.Box>
#               <Gtk.ListBox>
#                 <Adw.EntryRow id="username_entry" />
#               </Gtk.ListBox>
#               <Gtk.ListBox>
#                 <Adw.PasswordEntryRow id="password_entry" />
#               </Gtk.ListBox>
#               <Gtk.Button id="sso_button" />
#               <LoadingButton id="next_button" />
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

  flows = Array(session[:matrix_flows])

  render(
    "matrix/login/method",
    homeserver:   base_url,
    domain:       session[:matrix_domain],
    supportsSso:  flows.include?("m.login.sso"),
    supportsPassword: flows.include?("m.login.password"),
    providers:    Matrix::Homeserver.identity_providers(base_url).map do |provider|
      { id: provider["id"], name: provider["name"] }
    end,
    error: session.delete(:matrix_method_error),
  )
end

# m.login.password, which is the form on this page. SSO leaves for the browser instead, so it is
# the in-browser page's POST and not this one's.
post "/" do
  base_url = session[:matrix_base_url].to_s

  if base_url.empty?
    redirect("/matrix/login/homeserver", 303)
  end

  answer = Matrix::Homeserver.password_login(
    base_url,
    params["username"].to_s,
    params["password"].to_s,
    matrix_device_id,
  )

  if answer.nil?
    session[:matrix_method_error] = "the homeserver rejected that username and password"
    redirect("/matrix/login/method", 303)
  end

  store_session(base_url, answer)

  redirect("/matrix/login/setup", 303)
end

__END__

import { Form, Head, Link } from "@inertiajs/react"
import { ArrowLeft } from "lucide-react"

import { Alert, AlertDescription, AlertTitle } from "@/components/reui/alert"
import { Button } from "@/components/ui/button"
import { Field, FieldGroup, FieldLabel } from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import { ShellHeader } from "@/components/admin/slots"

export default function MatrixLoginMethod({
  homeserver,
  domain,
  supportsSso,
  supportsPassword,
  providers,
  error,
}: {
  homeserver: string
  domain: string | null
  supportsSso: boolean
  supportsPassword: boolean
  providers: { id: string; name: string }[]
  error: string | null
}) {
  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title="Log In" />

      <ShellHeader>
        <Link
          href="/matrix/login/homeserver"
          className="text-muted-foreground hover:text-foreground"
        >
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">Log In</h1>
      </ShellHeader>

      <div className="mx-auto flex w-full max-w-md flex-col gap-6 p-6">
        <div className="flex flex-col gap-1">
          <h2 className="text-xl font-semibold tracking-tight">
            {domain ? `Log in to ${domain}` : "Log in"}
          </h2>
          <p className="font-mono text-xs text-muted-foreground">
            {homeserver.replace(/\/$/, "")}
          </p>
        </div>

        {error ? (
          <Alert variant="destructive">
            <AlertTitle>Could not sign in</AlertTitle>
            <AlertDescription>{error}</AlertDescription>
          </Alert>
        ) : null}

        {supportsPassword ? (
          <Form action="/matrix/login/method" method="post" className="flex flex-col gap-4">
            {({ processing }) => (
              <>
                <FieldGroup>
                  <Field>
                    <FieldLabel htmlFor="username">Matrix Username</FieldLabel>
                    <Input
                      id="username"
                      name="username"
                      autoFocus
                      autoCapitalize="none"
                      spellCheck={false}
                    />
                  </Field>
                  <Field>
                    <FieldLabel htmlFor="password">Password</FieldLabel>
                    <Input id="password" name="password" type="password" />
                  </Field>
                </FieldGroup>

                <Button type="submit" disabled={processing} className="self-center">
                  Next
                </Button>
              </>
            )}
          </Form>
        ) : (
          <Alert>
            <AlertTitle>No password login</AlertTitle>
            <AlertDescription>
              This homeserver does not advertise m.login.password.
            </AlertDescription>
          </Alert>
        )}

        {/* Fractal shows the SSO button only when the homeserver advertises the flow
            (method_page.rs: sso_button.set_visible(data.supports_sso)). */}
        {supportsSso ? (
          <div className="flex flex-col gap-2 border-t pt-4">
            {providers.length ? (
              providers.map((provider) => (
                <Button
                  key={provider.id}
                  variant="outline"
                  render={
                    <Link
                      href={`/matrix/login/browser?provider=${encodeURIComponent(provider.id)}`}
                    />
                  }
                >
                  Login via {provider.name}
                </Button>
              ))
            ) : (
              <Button variant="outline" render={<Link href="/matrix/login/browser" />}>
                Login via SSO
              </Button>
            )}
          </div>
        ) : null}
      </div>
    </div>
  )
}
