import { createMDX } from 'fumadocs-mdx/next';

const withMDX = createMDX();

// GitHub Pages serves the site from the repository's subpath, which the deploy workflow passes in.
// It is empty for `next dev`, so the site works at the root locally.
const basePath = process.env.NEXT_PUBLIC_BASE_PATH ?? '';

/** @type {import('next').NextConfig} */
const config = {
  reactStrictMode: true,
  // Static export: Pages has no Node server, so every route is prerendered into `out/`.
  output: 'export',
  // Pages serves `path/` rather than `path`, so link to the former and avoid a redirect.
  trailingSlash: true,
  basePath,
};

export default withMDX(config);
