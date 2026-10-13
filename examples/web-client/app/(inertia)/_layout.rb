# frozen_string_literal: true

enable :sessions

helpers Ratalada::Contrib::Vite::TagHelpers
helpers Ratalada::Contrib::Inertia::Helpers

template :layout do
  <<~ERB
    <!doctype html>
    <html>
      <head>
        <meta charset=utf-8>
        <meta name=viewport content="width=device-width,initial-scale=1">
        <title>Matrix</title>
        <%= vite_client_tag %>
        <%= vite_react_refresh_tag %>
        <%= vite_javascript_tag "application.tsx" %>
      </head>
      <body>
        <!-- The Inertia page object, in the script element @inertiajs/* v3
             reads it from (the data-page attribute form is v2). The client
             mounts the component named in it: the TSX after __END__ in that
             app/*.rb. -->
        <script data-page="app" type="application/json"><%= MultiJson.dump(@page).gsub("/", "\\\\/") %></script>
        <div id="app"></div>
      </body>
    </html>
  ERB
end

Inertia.share do
  { flash: session.delete(:flash) }
end

__END__

import { router, usePage } from "@inertiajs/react"
import { useEffect, useState, type ComponentType, type ReactNode } from "react"
import pages from "virtual:pages"

import { AppShell } from "@/components/admin/app-shell"
import { Dialog, DialogContent } from "@/components/ui/dialog"

type ModalData = {
  component: string
  props: Record<string, unknown>
  url: string
}

// A modal route renders its page *under* the dialog: render_modal sends the background page plus a
// `modal` prop naming the component to put on top of it, loaded from the same virtual:pages map the
// resolver uses. Fractal's Adw.Dialog views are these -- upgrade_dialog, create_direct_chat_dialog,
// login/advanced_dialog -- and `url` is where closing navigates back to.
function ModalHost() {
  const modal = usePage<{ modal?: ModalData }>().props.modal
  const [current, setCurrent] = useState<{ name: string; component: ComponentType } | null>(null)

  useEffect(() => {
    const name = modal?.component
    if (!name || current?.name === name) return
    let alive = true
    pages[name]?.().then((module) => {
      if (alive) setCurrent({ name, component: module.default })
    })
    return () => {
      alive = false
    }
  }, [modal?.component, current?.name])

  if (!modal || current?.name !== modal.component) return null

  return (
    <Dialog
      open
      onOpenChange={(open) => {
        if (!open) router.visit(modal.url, { preserveScroll: true })
      }}
    >
      <DialogContent>
        <current.component {...modal.props} />
      </DialogContent>
    </Dialog>
  )
}

export default function AdminLayout({ children }: { children: ReactNode }) {
  return (
    <AppShell>
      {children}
      <ModalHost />
    </AppShell>
  )
}
