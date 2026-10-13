# frozen_string_literal: true

# /matrix/login/advanced — Advanced homeserver settings
#
# Fractal: login/advanced_dialog.{blp,rs}
#
# NOT IMPLEMENTED.
#
# The sliding-sync proxy and any override the homeserver's well-known did not supply.
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
    background_props: {},
    component:        "matrix/login/advanced",
    props:            {},
    url:              "/matrix/login/homeserver",
  )
end

post "/" do
  halt(501, "matrix: not implemented\n")
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
import { Field, FieldGroup, FieldLabel } from "@/components/ui/field"
import { Input } from "@/components/ui/input"

export default function MatrixLoginAdvanced() {
  return (
    <>
      <Head title="Advanced homeserver settings" />

      <Form action="/matrix/login/advanced" method="post" className="contents">
        {({ processing }) => (
          <>
            <DialogHeader>
              <DialogTitle>Advanced</DialogTitle>
              <DialogDescription>
                Overrides for what the homeserver's well-known did not supply.
              </DialogDescription>
            </DialogHeader>

            <FieldGroup>
              <Field>
                <FieldLabel htmlFor="sliding_sync_url">Sliding sync proxy</FieldLabel>
                <Input id="sliding_sync_url" name="sliding_sync_url" placeholder="https://" />
              </Field>
            </FieldGroup>

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
