declare module "virtual:pages" {
  type Page = React.ComponentType<any> & { layout?: unknown }
  const pages: Record<string, () => Promise<{ default: Page }>>
  export default pages
}
