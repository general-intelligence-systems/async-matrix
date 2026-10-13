import { globSync, readFileSync } from "node:fs"
import { resolve } from "node:path"
import { defineConfig, transformWithOxc, type Plugin } from "vite"
import RubyPlugin from "vite-plugin-ruby"
import react from "@vitejs/plugin-react"
import tailwindcss from "@tailwindcss/vite"

const APP = resolve(import.meta.dirname, "app")

// Everything after __END__ in a .rb file: the page or email template it carries.
const endBlock = (file: string) => {
  const source = readFileSync(file, "utf8")
  const end = source.match(/^__END__\n/m)
  return end ? source.slice(end.index! + end[0].length) : null
}

// Pages live in the __END__ block of their route file: app/login.rb serves
// GET /login and carries the Login component after __END__. This exposes each
// one to Vite as a .tsx module, and `virtual:pages` as the name -> import map
// the Inertia resolver reads.
// A route group -- app/(inertia)/cluster/scans.rb -- is invisible in the URL the
// ruby router builds (Mustermann::Expo.route drops any "(name)" segment), so it
// has to be invisible in the page name too. Otherwise render("cluster/scans")
// asks for a key the map spells "(inertia)/cluster/scans" and every page 404s
// in the resolver.
const pageName = (file: string) =>
  file
    .split("/")
    .filter((segment) => !/^\(.+\)$/.test(segment))
    .join("/")

function rubyPages(): Plugin {
  // name -> the .rb file carrying it, so the group segments live in exactly one
  // place: this map.
  const pages = () => {
    const found = new Map<string, string>()
    for (const file of globSync("**/*.rb", { cwd: APP })) {
      const absolute = resolve(APP, file)
      if (endBlock(absolute) !== null) found.set(pageName(file.slice(0, -3)), absolute)
    }
    return found
  }

  const names = () => [...pages().keys()]

  const template = (name: string) => {
    const file = pages().get(name)
    return file ? endBlock(file) : null
  }

  return {
    name: "ruby-pages",
    // app/ sits outside the Vite root (frontend/), so it isn't watched.
    configureServer: (server) => void server.watcher.add(APP),
    handleHotUpdate({ file, server }) {
      if (!file.startsWith(APP)) return
      // Nothing in the module graph points at the .rb file: the page is a
      // virtual module keyed by name, so a reload alone re-serves the module
      // vite already loaded. Invalidate the page and the name -> import map
      // (a new app/*.rb belongs in it) before asking the client to reload.
      const graph = server.environments.client.moduleGraph
      for (const id of [
        `\0virtual:page/${pageName(file.slice(APP.length + 1, -3))}.tsx`,
        "\0virtual:pages",
      ]) {
        const module = graph.getModuleById(id)
        if (module) graph.invalidateModule(module)
      }
      server.hot.send({ type: "full-reload" })
    },
    // "\0" marks these as virtual so nothing tries to read them off disk.
    resolveId: (id) => (id.startsWith("virtual:page") ? `\0${id}` : null),
    load(id) {
      if (id === "\0virtual:pages") {
        const entries = names()
          .map((name) => `  ${JSON.stringify(name)}: () => import("virtual:page/${name}.tsx"),`)
          .join("\n")
        return `export default {\n${entries}\n}\n`
      }
      if (id.startsWith("\0virtual:page/")) {
        const name = id.slice("\0virtual:page/".length, -".tsx".length)
        const tsx = template(name)
        // Virtual ids skip vite's own TSX transform in dev, so run it here.
        return tsx && transformWithOxc(tsx, `${name}.tsx`, { lang: "tsx" })
      }
      return null
    },
  }
}

export default defineConfig({
  plugins: [RubyPlugin(), react(), tailwindcss(), rubyPages()],
  resolve: {
    alias: { "@": resolve(import.meta.dirname, "frontend") },
  },
  optimizeDeps: { entries: ["frontend/**/*.tsx"] },
})
