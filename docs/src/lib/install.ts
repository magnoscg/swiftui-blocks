// The ways to install the skill, as /install/ gives them. Each was tried with a clean home for its agent.
export interface InstallWay {
  label: string;
  commands: string[];
  kind: 'skills-cli' | 'plugin';
  via: 'Skills CLI' | 'Plugin' | 'Extension';
  check?: { command: string; shows: string };
  update: string[];
}

export const SKILL_URL = 'https://github.com/magnoscg/swiftui-blocks-skill/blob/HEAD/skills/swiftui-blocks/SKILL.md';

const SKILL_RAW_URL = 'https://raw.githubusercontent.com/magnoscg/swiftui-blocks-skill/HEAD/skills/swiftui-blocks/SKILL.md';

const skillsCLI = (label: string): InstallWay => ({
  label,
  commands: ['npx skills add magnoscg/swiftui-blocks-skill'],
  kind: 'skills-cli',
  via: 'Skills CLI',
  update: ['npx skills update'],
});

export const installWays: InstallWay[] = [
  skillsCLI('Any agent'),
  {
    label: 'Claude Code',
    commands: [
      'claude plugin marketplace add magnoscg/swiftui-blocks-skill',
      'claude plugin install swiftui-blocks@swiftuiblocks',
    ],
    kind: 'plugin',
    via: 'Plugin',
    check: { command: 'claude plugin list', shows: 'swiftui-blocks@swiftuiblocks' },
    update: ['claude plugin marketplace update swiftuiblocks', 'claude plugin update swiftui-blocks@swiftuiblocks'],
  },
  {
    label: 'Codex',
    commands: ['codex plugin marketplace add magnoscg/swiftui-blocks-skill', 'codex plugin add swiftui-blocks@swiftuiblocks'],
    kind: 'plugin',
    via: 'Plugin',
    update: ['codex plugin marketplace upgrade swiftuiblocks'],
  },
  {
    label: 'Copilot CLI',
    commands: [
      'copilot plugin marketplace add magnoscg/swiftui-blocks-skill',
      'copilot plugin install swiftui-blocks@swiftuiblocks',
    ],
    kind: 'plugin',
    via: 'Plugin',
    check: { command: 'copilot skill list', shows: 'swiftui-blocks' },
    update: ['copilot plugin update swiftui-blocks'],
  },
  {
    label: 'Gemini CLI',
    commands: ['gemini extensions install https://github.com/magnoscg/swiftui-blocks-skill'],
    kind: 'plugin',
    via: 'Extension',
    check: { command: 'gemini extensions list', shows: 'swiftui-blocks' },
    update: ['gemini extensions update swiftui-blocks'],
  },
];

// Cursor takes the skill through the skills CLI, so the landing page counts it under Any agent.
export const installAgents: InstallWay[] = [...installWays, skillsCLI('Cursor')];

export const byHand = [
  {
    agents: 'Claude Code',
    command: `mkdir -p ~/.claude/skills/swiftui-blocks && curl -fsS -o ~/.claude/skills/swiftui-blocks/SKILL.md ${SKILL_RAW_URL}`,
  },
  {
    agents: 'Codex, Copilot CLI, Cursor and Gemini CLI',
    command: `mkdir -p ~/.agents/skills/swiftui-blocks && curl -fsS -o ~/.agents/skills/swiftui-blocks/SKILL.md ${SKILL_RAW_URL}`,
  },
];

export const agentId = (label: string) => label.toLowerCase().replace(/[^a-z0-9]+/g, '-');
