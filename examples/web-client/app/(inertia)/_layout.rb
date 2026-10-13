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

import type { ReactNode } from "react"

import { AppShell } from "@/components/admin/app-shell"

export default function AdminLayout({ children }: { children: ReactNode }) {
  return <AppShell>{children}</AppShell>
}
