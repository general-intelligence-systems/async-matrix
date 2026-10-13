# frozen_string_literal: true

# /matrix/login/advanced — Advanced homeserver settings
#
# Fractal: login/advanced_dialog.{blp,rs}
#
# One switch: Auto-Discovery. On, the entry is a domain resolved through its well-known; off, it is
# the homeserver URL as typed. Fractal titles the dialog "Homeserver Discovery" and it holds nothing
# else.
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
# login/advanced_dialog.blp
#
#   <Adw.PreferencesDialog id="LoginAdvancedDialog">
#     <Adw.PreferencesPage>
#       <Adw.PreferencesGroup>
#         <Adw.SwitchRow />
#       </Adw.PreferencesGroup>
#     </Adw.PreferencesPage>
#   </Adw.PreferencesDialog>
#

# A MODAL ROUTE, because advanced_dialog is an Adw.Dialog and not a page in Fractal's login
# NavigationView. render_modal sends the homeserver page as the background with this dialog's own
# component on top, and closing it navigates back to `url`.
get "/" do
  render_modal(
    background:       "matrix/login/homeserver",
    background_props: {
      autodiscovery: session.fetch(:matrix_autodiscovery, true),
      value:         session[:matrix_homeserver_input].to_s,
      error:         nil,
    },
    component:        "matrix/login/advanced",
    props:            { autodiscovery: session.fetch(:matrix_autodiscovery, true) },
    url:              "/matrix/login/homeserver",
  )
end

post "/" do
  session[:matrix_autodiscovery] = params["autodiscovery"].to_s == "true"

  redirect("/matrix/login/homeserver", 303)
end

__END__

import { Form, Head } from "@inertiajs/react"

import { Button } from "@/components/ui/button"
import {
  DialogClose,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import { Field, FieldDescription, FieldLabel } from "@/components/ui/field"
import { Switch } from "@/components/ui/switch"

export default function MatrixLoginAdvanced({ autodiscovery }: { autodiscovery: boolean }) {
  return (
    <>
      <Head title="Homeserver Discovery" />

      <Form action="/matrix/login/advanced" method="post" className="contents">
        {({ processing }) => (
          <>
            <DialogHeader>
              <DialogTitle>Homeserver Discovery</DialogTitle>
              <DialogDescription>
                Whether the homeserver entry is a domain to look up or a URL to use as given.
              </DialogDescription>
            </DialogHeader>

            <Field orientation="horizontal">
              <FieldLabel htmlFor="autodiscovery">Auto-Discovery</FieldLabel>
              <Switch id="autodiscovery" name="autodiscovery" value="true" defaultChecked={autodiscovery} />
              <FieldDescription>
                Looks the domain up in its .well-known/matrix/client.
              </FieldDescription>
            </Field>

            <DialogFooter className="gap-2">
              <Button type="submit" disabled={processing}>
                Save
              </Button>
              <DialogClose render={<Button variant="ghost" type="button" />}>Cancel</DialogClose>
            </DialogFooter>
          </>
        )}
      </Form>
    </>
  )
}
