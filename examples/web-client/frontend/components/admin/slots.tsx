"use client"

import {
  createContext,
  useCallback,
  useContext,
  useLayoutEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react"
import { createPortal } from "react-dom"

// THE SHELL OWNS THE CHROME, THE PAGE FILLS IT. A page's sidebar list and its
// header bar belong to the one shell in app/(inertia)/_layout.rb -- a page that
// builds its own ends up with a header inside a header and a list beside the
// shell's rather than in it.
//
// Upwards is the direction React does not render in, so a page hands content to
// the shell through a portal: the shell marks where each slot lands, the page
// renders <ShellHeader>/<ShellSidebar> wherever it likes in its own tree, and
// the content comes out in the shell's chrome.
export type ShellSlot = "sidebar" | "header"

type Slots = Record<ShellSlot, HTMLElement | null>
type Claims = Record<ShellSlot, number>

type Store = {
  nodes: Slots
  claims: Claims
  mount: (slot: ShellSlot, node: HTMLElement | null) => void
  // Returns the release, so a page that navigates away gives the slot back and
  // the shell can collapse it again.
  claim: (slot: ShellSlot) => () => void
}

const ShellSlotsContext = createContext<Store | null>(null)

function useStore() {
  const store = useContext(ShellSlotsContext)
  if (!store) throw new Error("shell slots: no <ShellSlots> above this component")
  return store
}

export function ShellSlots({ children }: { children: ReactNode }) {
  const [nodes, setNodes] = useState<Slots>({ sidebar: null, header: null })
  const [claims, setClaims] = useState<Claims>({ sidebar: 0, header: 0 })

  // Compared before storing: a ref callback fires on every commit and an
  // unconditional setState here is an infinite render.
  const mount = useCallback((slot: ShellSlot, node: HTMLElement | null) => {
    setNodes((current) => (current[slot] === node ? current : { ...current, [slot]: node }))
  }, [])

  // Counted rather than a boolean, so the claim and the release of two pages
  // crossing over a navigation cannot leave the slot stuck closed.
  const claim = useCallback((slot: ShellSlot) => {
    setClaims((current) => ({ ...current, [slot]: current[slot] + 1 }))
    return () => setClaims((current) => ({ ...current, [slot]: current[slot] - 1 }))
  }, [])

  const store = useMemo(() => ({ nodes, claims, mount, claim }), [nodes, claims, mount, claim])

  return <ShellSlotsContext.Provider value={store}>{children}</ShellSlotsContext.Provider>
}

// ── The shell side ──

// Hang this on the element a slot's content should land inside.
export function useShellSlotRef(slot: ShellSlot) {
  const { mount } = useStore()
  return useCallback((node: HTMLElement | null) => mount(slot, node), [mount, slot])
}

// Whether anything below has claimed the slot -- what the shell reads to decide
// whether the sidebar panel exists at all, and how wide it is.
export function useShellSlotFilled(slot: ShellSlot) {
  return useStore().claims[slot] > 0
}

// ── The page side ──

// useLayoutEffect, not useEffect: the claim has to reach the shell in the same
// commit, or the panel is briefly a rail and the layout visibly settles.
function Slot({ slot, children }: { slot: ShellSlot; children: ReactNode }) {
  const { nodes, claim } = useStore()

  useLayoutEffect(() => claim(slot), [claim, slot])

  const node = nodes[slot]

  return node ? createPortal(children, node) : null
}

// The list beside the icon rail, inside the shell's Sidebar.
export function ShellSidebar({ children }: { children: ReactNode }) {
  return <Slot slot="sidebar">{children}</Slot>
}

// The row inside the shell's one header bar, after the sidebar trigger.
export function ShellHeader({ children }: { children: ReactNode }) {
  return <Slot slot="header">{children}</Slot>
}
