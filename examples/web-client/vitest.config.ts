import { resolve } from "node:path"
import { defineConfig } from "vitest/config"
import react from "@vitejs/plugin-react"

// Vitest runs against the same frontend source, but nothing here needs the
// ruby-pages / ruby-emails virtual modules or the dev server host rules — a
// plain react transform plus the "@/frontend" alias is the whole config.
export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: { "@": resolve(import.meta.dirname, "frontend") },
  },
  test: {
    environment: "jsdom",
    // CSS is a build-time concern: components are asserted on DOM, not styles,
    // so a stray .css import should be a no-op rather than a pipeline.
    css: false,
    setupFiles: ["./tests/frontend/setup.ts"],
    include: ["tests/frontend/**/*.test.{ts,tsx}"],
  },
})