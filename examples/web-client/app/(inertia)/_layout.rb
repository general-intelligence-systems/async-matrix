# frozen_string_literal: true

enable :sessions

helpers Ratalada::Contrib::Vite::TagHelpers
helpers Ratalada::Contrib::Inertia::Helpers

helpers do
end

template :layout do
  <<~ERB
    <!doctype html>
    <html>
      <head>
        <meta charset=utf-8>
        <meta name=viewport content="width=device-width,initial-scale=1">
        <title>todo-mvc</title>
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

share do
  {
    flash: session.delete(:admin_flash),
    admin: {
      environment: ENV.fetch("RACK_ENV", "development"),
      sections:    [
        { title: "Overview", href: "/", icon: "gauge" },
        { title: "Notifications", href: "/notifications", icon: "bell" },
        {
          title:    "Tables",
          href:     "/table",
          icon:     "table",
          children: admin_tables.map(&:to_s).sort.map do |table|
            { title: table, href: "/table/#{table}" }
          end,
        },
        {
          title:    "Cluster",
          href:     "/cluster",
          icon:     "containers",
          children: [
            { title: "Workloads", href: "/cluster/workloads" },
            { title: "Port forwards", href: "/cluster/portforwards" },
            { title: "Image scans", href: "/cluster/scans" },
            { title: "Pulses", href: "/cluster/pulses" },
          ],
        },
        # The Matrix client (app/matrix). ONE ENTRY: picking a room is a row in
        # the sidebar that app/matrix/_layout.rb shares with every page under
        # it, not a nav item -- and the room list is the one list that changes
        # on every incoming message, so a nav built from it would be rebuilt
        # constantly for no benefit.
        { title: "Matrix", href: "/matrix", icon: "messages-square" },
        # The secret store panel: what this app holds encrypted, plus the
        # ExternalSecrets and SecretStores the cluster built from it.
        { title: "Secret store", href: "/secrets", icon: "key" },
        # The Vikunja screens (app/tasks, app/projects, app/labels, app/teams),
        # served out of the instance at VIKUNJA_URL.
        #
        # TASKS FIRST, AND TOP LEVEL: Vikunja's landing page is a task list, not
        # a dashboard, so /tasks is the way in -- burying it under Projects hid
        # the one screen that is about tasks rather than about a project.
        {
          title:    "Tasks",
          href:     "/tasks",
          icon:     "list-checks",
          children: [
            { title: "Upcoming", href: "/tasks/by/upcoming" },
          ],
        },
        { title: "Labels", href: "/labels", icon: "tags" },
        { title: "Teams", href: "/teams", icon: "users" },
        { title: "Tickets", href: "/tickets", icon: "ticket" },
        { title: "RBAC analysis", href: "/rbac", icon: "shield" },
        { title: "Popeye", href: "/popeye", icon: "stethoscope" },
        { title: "Timers", href: "/timers", icon: "timer" },
        {
          title:    "Operaton",
          href:     "/operaton",
          icon:     "workflow",
          children: [
            { title: "Processes", href: "/operaton/processes" },
            { title: "Tasks", href: "/operaton/tasks" },
            { title: "Decisions", href: "/operaton/decisions" },
            { title: "Deployments", href: "/operaton/deployments" },
            { title: "Batches", href: "/operaton/batches" },
            { title: "Migrations", href: "/operaton/migrations" },
            { title: "Users", href: "/operaton/users" },
            { title: "Groups", href: "/operaton/groups" },
            { title: "Tenants", href: "/operaton/tenants" },
            { title: "Authorizations", href: "/operaton/authorizations" },
            { title: "System", href: "/operaton/system" },
          ],
        },
        { title: "Cosmo", href: "/cosmo", icon: "rocket", external: true },
        {
          title:    "Errors",
          href:     Signoz.exceptions_url,
          icon:     "bug",
          external: true,
        },
        *(
          if ENV["RACK_ENV"] == "production"
            []
          else
            [
              { title: "Inbox", href: "/mail", icon: "inbox" },
              {
                title:    "Mailer templates",
                href:     "/mail/templates",
                icon:     "mails",
                children: mailer_templates.keys.sort.map do |template|
                  { title: template, href: "/mail/templates/#{template}" }
                end,
              },
            ]
          end
        ),
      ],
    },
  }
end

__END__

import type { ReactNode } from "react"

import { AppShell } from "@/components/admin/app-shell"

export default function AdminLayout({ children }: { children: ReactNode }) {
  return <AppShell>{children}</AppShell>
}
