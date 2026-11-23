// The landing page comes in English at / and in Spanish at /es/, so Google finds it in both. Only the landing
// page is translated: the rest of the site, its header and its search stay in English.
import { SITE_BASE } from './catalog';

export type LandingLang = 'en' | 'es';

export const landingPaths: Record<LandingLang, string> = {
  en: `${SITE_BASE}/`,
  es: `${SITE_BASE}/es/`,
};

export const landingLang = (pathname: string) =>
  (Object.keys(landingPaths) as LandingLang[]).find((lang) => landingPaths[lang] === pathname);

export const landingText = {
  en: {
    languageName: 'English',
    anyAgent: 'Any agent',
    copy: 'Copy',
    copied: 'Copied',
    copyCommand: 'Copy the command',
    copyCommands: 'Copy both commands',
    skillsNote: 'Recommended. Works with Claude Code, Codex, Copilot CLI, Cursor, Gemini CLI and other agents that read skills. Needs Node; without it,',
    skillsByHand: 'add it by hand',
    readSkill: 'Read the skill',
    pluginNote: 'Use one way on each computer: with two copies, your agent loads one, and updating the other changes nothing.',
    allOptions: 'All options',
    stripTitle: 'What you ask, and what your agent adds',
    searchLabel: 'Describe what you need',
    searchPlaceholder: 'Try “button that shines”…',
    searchNothing: 'Nothing fits those words. Try others, or browse the catalog.',
    searchOne: '1 component',
    searchMany: 'components',
    cardAlt:
      'SwiftUI Blocks: SwiftUI components your agent can add. The command npx skills add magnoscg/swiftui-blocks-skill, next to Holographic Card, Glass Tool Strip and Activity Rings on iPhone.',
    slackComponents: 'Components',
    slackRange: 'iOS 18 to 27',
    slackWorksWith: 'Works with',
    slackAgents: 'Claude Code, Codex & more',
  },
  es: {
    languageName: 'Español',
    anyAgent: 'Cualquier agente',
    copy: 'Copiar',
    copied: 'Copiado',
    copyCommand: 'Copiar el comando',
    copyCommands: 'Copiar los dos comandos',
    skillsNote: 'Recomendado. Funciona con Claude Code, Codex, Copilot CLI, Cursor, Gemini CLI y otros agentes que leen skills. Necesita Node; sin él,',
    skillsByHand: 'añádela a mano',
    readSkill: 'Leer la skill',
    pluginNote: 'Usa una sola vía en cada ordenador: con dos copias, tu agente carga una, y actualizar la otra no cambia nada.',
    allOptions: 'Todas las opciones',
    stripTitle: 'Lo que pides y lo que añade tu agente',
    searchLabel: 'Describe lo que necesitas',
    searchPlaceholder: 'Prueba con «botón que brilla»…',
    searchNothing: 'Nada encaja con esas palabras. Prueba con otras o explora el catálogo.',
    searchOne: '1 componente',
    searchMany: 'componentes',
    cardAlt:
      'SwiftUI Blocks: componentes SwiftUI que tu agente añade. El comando npx skills add magnoscg/swiftui-blocks-skill, junto a Holographic Card, Glass Tool Strip y Activity Rings en un iPhone.',
    slackComponents: 'Componentes',
    slackRange: 'iOS 18 a 27',
    slackWorksWith: 'Funciona con',
    slackAgents: 'Claude Code, Codex y más',
  },
} satisfies Record<LandingLang, Record<string, unknown>>;
