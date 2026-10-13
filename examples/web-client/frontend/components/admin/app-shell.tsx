"use client"

import type { CSSProperties, ReactNode } from "react"

import { Sidebar, SidebarInset, SidebarProvider, SidebarTrigger } from "@/components/ui/sidebar"
import { Toaster } from "@/components/ui/sonner"

import { ShellSlots, useShellSlotFilled, useShellSlotRef } from "./slots"

// The chrome every page is drawn inside: one sidebar, one header bar, and the
// page under it.
//
// THIS SHELL HAS NO NAVIGATION OF ITS OWN, which is the whole difference from
// the admin shell this file is named after. There is nothing for it to navigate
// to: a Matrix client is one session's room list, and that list is the sidebar
// rather than something beside it. app/(inertia)/matrix/_layout.rb renders it
// into <ShellSidebar> and each page puts its own title bar into <ShellHeader>,
// so what is left here is the frame those two land in.
export function AppShell({ children }: { children?: ReactNode }) {
  return (
    <ShellSlots>
      <Shell>{children}</Shell>
    </ShellSlots>
  )
}

// Inside the provider, because the width below is decided by what the page has
// claimed and useShellSlotFilled needs the store.
function Shell({ children }: { children?: ReactNode }) {
  const sidebar = useShellSlotRef("sidebar")
  const header = useShellSlotRef("header")

  // A page that fills the sidebar slot gets a panel; one that does not gets the
  // rail alone. /matrix/login is the second kind on purpose -- see the comment
  // in matrix/_layout.rb: before a device exists there is no room list, so the
  // panel would be an empty pane framing the one control that matters.
  const panel = useShellSlotFilled("sidebar")

  return (
    <SidebarProvider
      className="h-screen"
      style={
        {
          "--sidebar-width": panel ? "360px" : "0px",
          "--header-height": "50px",
        } as CSSProperties
      }
    >
      {/* collapsible="none": the panel's presence is the slot's business, so
          there is no rail to collapse it to and no trigger to do it with. */}
      <Sidebar collapsible="none" className={panel ? "border-r" : "hidden"}>
        <div ref={sidebar} className="flex min-h-0 flex-1 flex-col" />
      </Sidebar>

      <SidebarInset className="min-w-0">
        <header className="flex h-(--header-height) shrink-0 items-center gap-2 border-b px-3">
          <SidebarTrigger className="-ml-1" />
          <div ref={header} className="flex min-w-0 flex-1 items-center gap-2" />
        </header>

        <div className="flex min-h-0 flex-1 flex-col overflow-y-auto">{children}</div>
      </SidebarInset>

      <Toaster />
    </SidebarProvider>
  )
}
