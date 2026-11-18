// Gives the page of each component its own social card in place of the one
// of the site, which astro.config.mjs sets for every other page, and gives the
// landing page the two extra rows Slack shows under a shared link.
import { defineRouteMiddleware } from '@astrojs/starlight/route-data';
import { cardURL, components, count } from './lib/catalog';

export const onRequest = defineRouteMiddleware((context) => {
  const { entry, head } = context.locals.starlightRoute;
  if (entry.data.hero) {
    head.push(
      { tag: 'meta', attrs: { name: 'twitter:label1', content: 'Components' } },
      { tag: 'meta', attrs: { name: 'twitter:data1', content: `${count} · iOS 18 to 27` } },
      { tag: 'meta', attrs: { name: 'twitter:label2', content: 'Works with' } },
      { tag: 'meta', attrs: { name: 'twitter:data2', content: 'Claude Code, Codex & more' } },
    );
    return;
  }

  const [section, , id] = entry.id.split('/');
  const component = section === 'catalog' ? components.find((candidate) => candidate.id === id) : undefined;
  if (!component) return;

  const card = cardURL(component);
  const alt = `${component.title}, running on iPhone.`;
  const replacements: Record<string, string> = {
    'og:image': card,
    'og:image:alt': alt,
    'twitter:image': card,
    'twitter:image:alt': alt,
  };
  for (const tag of head) {
    const key = tag.attrs?.property ?? tag.attrs?.name;
    if (tag.tag === 'meta' && typeof key === 'string' && key in replacements) tag.attrs!.content = replacements[key];
  }
});
