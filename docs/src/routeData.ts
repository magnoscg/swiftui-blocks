// Gives the page of each component its own social card in place of the one
// of the site, which astro.config.mjs sets for every other page. The landing
// page, in English at / and in Spanish at /es/, gets its language, the links
// between its two versions, its card and the two extra rows Slack shows under
// a shared link.
import { defineRouteMiddleware } from '@astrojs/starlight/route-data';
import { cardURL, components, count } from './lib/catalog';
import { landingLang, landingPaths, landingText, type LandingLang } from './lib/landing';

type HeadTags = App.Locals['starlightRoute']['head'];

const SPANISH_CARD = 'https://swiftuiblocks.dev/social-card-es.jpg';

const replaceMeta = (head: HeadTags, replacements: Record<string, string>) => {
  for (const tag of head) {
    const key = tag.attrs?.property ?? tag.attrs?.name;
    if (tag.tag === 'meta' && typeof key === 'string' && key in replacements) tag.attrs!.content = replacements[key];
  }
};

export const onRequest = defineRouteMiddleware((context) => {
  const route = context.locals.starlightRoute;
  const { entry, head } = route;

  const lang = landingLang(context.url.pathname);
  if (lang) {
    const text = landingText[lang];
    const langs = Object.keys(landingPaths) as LandingLang[];
    // Without Starlight's locales, which would add a Spanish copy of every page, the language is set here.
    route.lang = lang;
    route.entryMeta.lang = lang;
    replaceMeta(head, { 'og:locale': lang });
    if (lang === 'es') {
      replaceMeta(head, {
        'og:image': SPANISH_CARD,
        'og:image:alt': text.cardAlt,
        'twitter:image': SPANISH_CARD,
        'twitter:image:alt': text.cardAlt,
      });
    }
    const alternate = (hreflang: string, path: string) => ({
      tag: 'link' as const,
      attrs: { rel: 'alternate', hreflang, href: new URL(path, context.site).href },
    });
    head.push(
      ...langs
        .filter((other) => other !== lang)
        .map((other) => ({ tag: 'meta' as const, attrs: { property: 'og:locale:alternate', content: other } })),
      ...langs.map((each) => alternate(each, landingPaths[each])),
      alternate('x-default', landingPaths.en),
      { tag: 'meta', attrs: { name: 'twitter:label1', content: text.slackComponents } },
      { tag: 'meta', attrs: { name: 'twitter:data1', content: `${count} · ${text.slackRange}` } },
      { tag: 'meta', attrs: { name: 'twitter:label2', content: text.slackWorksWith } },
      { tag: 'meta', attrs: { name: 'twitter:data2', content: text.slackAgents } },
    );
    return;
  }

  const [section, , id] = entry.id.split('/');
  const component = section === 'catalog' ? components.find((candidate) => candidate.id === id) : undefined;
  if (!component) return;

  const card = cardURL(component);
  const alt = `${component.title}, running on iPhone.`;
  replaceMeta(head, {
    'og:image': card,
    'og:image:alt': alt,
    'twitter:image': card,
    'twitter:image:alt': alt,
  });
});
