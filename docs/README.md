# Async::Matrix Documentation

The documentation site for `async-matrix`, built with [Fumadocs](https://fumadocs.dev) on
Next.js. It is a separate Node project from the gem, and nothing in `lib/` depends on it.

``` shell
npm install          # once
npm run dev          # http://localhost:3000
npm run build        # the static export, into `out/`
npm run types:check  # after a build, which is what types the routes
```

The Documentation workflow builds it and publishes `out/` to GitHub Pages. Pages has no Node
server, so the site is a static export: `output: "export"` prerenders every route, including the
search index and the OG images, and there is no middleware - which is why there is no `proxy.ts`
here, and why `/docs/<page>.md` is served as `/llms.mdx/docs/<page>/content.md` rather than
negotiated by `Accept`.

Pages also serves the site from the repository's subpath, which the build has to be told about or
every URL it emits is wrong. The workflow passes it as `NEXT_PUBLIC_BASE_PATH`, from
`actions/configure-pages`; `next dev` leaves it unset and serves from the root. Next prefixes
`next/link` and asset URLs itself, but not a URL fetched by hand, so `lib/shared.ts` builds the
search index URL from it explicitly.

The pages live in `content/docs` as MDX, one file per page, ordered by `content/docs/meta.json`.
Frontmatter carries the `title`, `description` and a [Lucide](https://lucide.dev) `icon` name,
which `lucideIconsPlugin` in `lib/source.ts` resolves for the sidebar.

| Path                      | Description                                                     |
| ------------------------- | --------------------------------------------------------------- |
| `content/docs`            | The pages, as MDX.                                              |
| `lib/source.ts`           | The content source: the MDX collection and the page tree.       |
| `lib/shared.ts`           | Site name, docs route and the GitHub repository the nav uses.   |
| `lib/layout.shared.tsx`   | Options shared by the docs and landing layouts.                 |
| `app/(home)`              | The landing page.                                               |
| `app/docs`                | The docs layout and the catch-all page route.                   |
| `app/api/search/route.ts` | The search index, exported once at build time by `staticGET`.    |

The content is written here rather than generated from `readme.md` and `guides/`, so a change to
either has to be made in both places. Two things do differ by necessity: the `{ruby ...}` link
syntax the guides use is `decode`'s, not MDX's, so it is written as plain inline code here, and
MDX reads a bare `{` as an expression, so braces in prose belong inside backticks.
