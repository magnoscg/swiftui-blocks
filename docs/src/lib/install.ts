// The ways to install the skill, as /install/ gives them. Each was tried with a clean home for its agent.
export interface InstallWay {
  label: string;
  commands: string[];
  kind: 'skills-cli' | 'plugin';
}

export const SKILL_URL = 'https://github.com/magnoscg/swiftui-blocks-skill/blob/HEAD/skills/swiftui-blocks/SKILL.md';

export const installWays: InstallWay[] = [
  {
    label: 'Any agent',
    commands: ['npx skills add magnoscg/swiftui-blocks-skill'],
    kind: 'skills-cli',
  },
  {
    label: 'Claude Code',
    commands: [
      'claude plugin marketplace add magnoscg/swiftui-blocks-skill',
      'claude plugin install swiftui-blocks@swiftuiblocks',
    ],
    kind: 'plugin',
  },
  {
    label: 'Codex',
    commands: ['codex plugin marketplace add magnoscg/swiftui-blocks-skill', 'codex plugin add swiftui-blocks@swiftuiblocks'],
    kind: 'plugin',
  },
  {
    label: 'Copilot CLI',
    commands: [
      'copilot plugin marketplace add magnoscg/swiftui-blocks-skill',
      'copilot plugin install swiftui-blocks@swiftuiblocks',
    ],
    kind: 'plugin',
  },
  {
    label: 'Gemini CLI',
    commands: ['gemini extensions install https://github.com/magnoscg/swiftui-blocks-skill'],
    kind: 'plugin',
  },
];
