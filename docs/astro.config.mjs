import starlight from '@astrojs/starlight';
import { defineConfig } from 'astro/config';

const SITE_CARD = 'https://swiftuiblocks.dev/social-card.jpg';
const SITE_CARD_ALT =
  'SwiftUI Blocks: SwiftUI components your agent can add. The command npx skills add magnoscg/swiftui-blocks-skill, next to Holographic Card, Glass Tool Strip and Activity Rings on iPhone.';
// stats.*, not umami.*: EasyPrivacy blocks `umami.*/script.js`.
const ANALYTICS_SCRIPT = 'https://stats.ogamlabs.com/script.js';
const ANALYTICS_WEBSITE_ID = 'c1bea8c2-8729-474d-af3e-8da4d7d24c0a';
// The script of Umami 3.5.0: after upgrading Umami, recompute it with `curl -fsS <script> -o script.js && openssl dgst -sha384 -binary script.js | openssl base64 -A`, or no visit counts.
const ANALYTICS_INTEGRITY = 'sha384-Ts03XUTV1nsmqXjhMgA3LGXKFnW1NLMAzbKGEaaDFUy7wUETechGFTNIXF7rAuqP';

export default defineConfig({
  site: 'https://swiftuiblocks.dev',
  // Pages that moved keep their old address working, since links to them are out there.
  redirects: {
    '/getting-started/': '/introduction/',
    '/for-ai-agents/': '/install/',
  },
  integrations: [
    starlight({
      title: 'SwiftUI Blocks',
      description:
        'Free SwiftUI components, animations and transitions for iOS 18 to 27. Your AI coding agent finds one and adds its Swift file to your app.',
      // The card shown when a page of the site is shared. A component page swaps it for its own in src/routeData.ts.
      routeMiddleware: './src/routeData.ts',
      head: [
        { tag: 'meta', attrs: { property: 'og:image', content: SITE_CARD } },
        { tag: 'meta', attrs: { property: 'og:image:width', content: '1200' } },
        { tag: 'meta', attrs: { property: 'og:image:height', content: '630' } },
        { tag: 'meta', attrs: { property: 'og:image:type', content: 'image/jpeg' } },
        { tag: 'meta', attrs: { property: 'og:image:alt', content: SITE_CARD_ALT } },
        { tag: 'meta', attrs: { name: 'twitter:card', content: 'summary_large_image' } },
        { tag: 'meta', attrs: { name: 'twitter:image', content: SITE_CARD } },
        { tag: 'meta', attrs: { name: 'twitter:image:alt', content: SITE_CARD_ALT } },
        // Umami counts visits without cookies. data-domains keeps local builds and `make docs-dev` from counting; the exclude attributes drop the query and fragment of every address, where personal data could travel.
        {
          tag: 'script',
          attrs: {
            defer: true,
            src: ANALYTICS_SCRIPT,
            integrity: ANALYTICS_INTEGRITY,
            crossorigin: 'anonymous',
            'data-website-id': ANALYTICS_WEBSITE_ID,
            'data-domains': 'swiftuiblocks.dev',
            'data-exclude-search': 'true',
            'data-exclude-hash': 'true',
          },
        },
      ],
      customCss: ['@fontsource-variable/outfit', './src/styles/custom.css'],
      components: {
        Hero: './src/components/Hero.astro',
        Header: './src/components/Header.astro',
        Sidebar: './src/components/Sidebar.astro',
        PageTitle: './src/components/PageTitle.astro',
      },
      sidebar: [
        { label: 'Get started', items: ['introduction', 'install', 'prompts', 'by-hand'] },
        { label: 'Reference', items: ['anatomy', 'rules', 'accessibility', 'files-for-agents'] },
        { label: 'Project', items: ['contributing', 'changelog', 'privacy'] },
        // 288 names do not fit in a sidebar: each category opens on demand.
        { label: 'Catalog', items: [{ autogenerate: { directory: 'catalog', collapsed: true } }] },
      ],
    }),
  ],
});
