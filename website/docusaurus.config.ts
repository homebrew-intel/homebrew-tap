import { themes as prismThemes } from "prism-react-renderer";
import type { Config } from "@docusaurus/types";
import type * as Preset from "@docusaurus/preset-classic";

const REPOSITORY = "https://github.com/macos-intel/homebrew-tap";

const config: Config = {
  title: "macOS Homebrew Intel",
  tagline: "Working to keep macOS Intel Brew builds maintained.",
  favicon: "homebrew-intel.ico",

  // Project page: https://macos-intel.github.io/homebrew-tap/
  url: "https://macos-intel.github.io",
  baseUrl: "/homebrew-tap/",
  organizationName: "macos-intel",
  projectName: "homebrew-tap",
  trailingSlash: false,

  onBrokenLinks: "throw",
  markdown: { hooks: { onBrokenMarkdownLinks: "throw" } },

  // The repository's img/ is served as-is, so the README and the site share
  // one copy of every image.
  staticDirectories: ["static", "../img"],

  i18n: { defaultLocale: "en", locales: ["en"] },

  presets: [
    [
      "classic",
      {
        docs: {
          sidebarPath: "./sidebars.ts",
          editUrl: `${REPOSITORY}/edit/main/website/`,
        },
        blog: false,
        theme: { customCss: "./src/css/custom.css" },
      } satisfies Preset.Options,
    ],
  ],

  themeConfig: {
    image: "homebrew-intel-avatar.png",
    // brew.sh has a single dark theme, so the colour-mode switch is hidden.
    colorMode: { defaultMode: "dark", disableSwitch: true, respectPrefersColorScheme: false },
    navbar: {
      title: "macOS Homebrew Intel",
      logo: { alt: "macOS Homebrew Intel logo", src: "homebrew-intel.svg" },
      items: [
        { type: "docSidebar", sidebarId: "docs", position: "left", label: "Docs" },
        { to: "/#bottles", label: "Bottles", position: "left" },
        { href: REPOSITORY, label: "GitHub", position: "right" },
      ],
    },
    footer: {
      style: "dark",
      links: [
        {
          title: "Docs",
          items: [
            { label: "Getting started", to: "/docs/getting-started" },
            { label: "The Intel warning", to: "/docs/intel-warning" },
          ],
        },
        {
          title: "Project",
          items: [
            { label: "GitHub", href: REPOSITORY },
            { label: "Releases", href: `${REPOSITORY}/releases` },
            { label: "Changelog", href: `${REPOSITORY}/blob/main/CHANGELOG.md` },
          ],
        },
      ],
      copyright:
        "BSD 2-Clause, like Homebrew. Not affiliated with or endorsed by Homebrew.",
    },
    prism: {
      theme: prismThemes.vsDark,
      darkTheme: prismThemes.vsDark,
      additionalLanguages: ["bash", "ruby"],
    },
  } satisfies Preset.ThemeConfig,
};

export default config;
