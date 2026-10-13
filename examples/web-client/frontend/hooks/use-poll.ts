import { router } from "@inertiajs/react"
import { useEffect } from "react"

// Re-fetch the current page's props on an interval. The sync loop is what moves
// a verification along, so a page waiting on the other side has to ask again.
export function usePoll(active: boolean, only: string[] = [], interval = 2000) {
  useEffect(() => {
    if (!active) {
      return
    }

    const timer = window.setInterval(() => {
      router.reload({ only })
    }, interval)

    return () => window.clearInterval(timer)
  }, [active, interval, only.join(",")])
}
