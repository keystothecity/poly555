module.exports = {
  title: "POLY555",
  url: "https://www.oskitone.com/",
  baseUrl: "/",
  onBrokenLinks: "throw",
  onBrokenMarkdownLinks: "warn",
  favicon: "img/favicon.ico",
  organizationName: "oskitone", // Usually your GitHub org/user name.
  projectName: "poly555", // Usually your repo name.
  themeConfig: {
    navbar: {
      title: "Oskitone POLY555 Assembly Guide"
    },
    footer: {
      style: "dark",
      copyright: `Copyright © ${new Date().getFullYear()} Oskitone. Built with Docusaurus.`
    }
  },
  presets: [
    [
      "@docusaurus/preset-classic",
      {
        docs: {
          path: "./docs",
          routeBasePath: "/",
          sidebarPath: require.resolve("./sidebars.js")
        },
        theme: {
          customCss: require.resolve("./src/css/custom.css")
        }
      }
    ]
  ]
};
