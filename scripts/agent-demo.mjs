// The exchanges the demo on the Introduction page replays, worked out from
// components.tsv and the Swift files the way the skill in
// skills/swiftui-blocks/SKILL.md does, so the demo cannot drift from the catalog.
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const RAW_BASE = 'https://raw.githubusercontent.com/magnoscg/swiftui-blocks/HEAD';
const LICENSE = '// SPDX-License-Identifier: MIT';

/** The deployment target of the app in the demo. */
export const DEMO_TARGET = '18.0';

/** The exchanges of the demo: what the person asks, the word the agent searches and the component it picks. */
export const DEMO_EXAMPLES = [
  { id: 'like', label: 'Like button', prompt: 'Add a like button that bursts into hearts', word: 'heart', pick: 'Buttons/LikeBurstButton' },
  { id: 'glass', label: 'Liquid Glass strip', prompt: 'Group my editing tools in a Liquid Glass strip', word: 'glass', pick: 'Glass/GlassToolStrip' },
];

/** Returns the lines of the index that contain the word, ignoring case, as `grep -i -F` does. */
export function searchIndex(tsv, word) {
  const needle = word.toLowerCase();
  return tsv
    .split('\n')
    .slice(1)
    .filter((line) => line && line.toLowerCase().includes(needle))
    .map((line) => {
      const [path, minIOS, shader, title, summary] = line.split('\t');
      const [category, name] = path.split('/');
      return { path, category, name, minIOS, shader, title, summary };
    });
}

/** Counts the lines of a Swift file as `wc -l` does, and checks its license header and its closing `#Preview`. */
export function checkSource(source, name) {
  const lines = source.split('\n');
  if (lines.at(-1) === '') lines.pop();
  return {
    lines: lines.length,
    license: lines[0] === LICENSE,
    preview: lines.slice(-3).join('\n') === `#Preview {\n    ${name}Demo()\n}`,
  };
}

function compareVersions(a, b) {
  const [left, right] = [a, b].map((version) => version.split('.').map(Number));
  for (let index = 0; index < Math.max(left.length, right.length); index += 1) {
    const difference = (left[index] ?? 0) - (right[index] ?? 0);
    if (difference !== 0) return difference;
  }
  return 0;
}

/**
 * Replays one exchange: the search, the check of the minimum iOS and, when it
 * fits, the file the agent adds. Throws when the catalog no longer supports it.
 */
export function agentRun({ tsv, readSource, example, target }) {
  const matches = searchIndex(tsv, example.word);
  const pick = matches.find((row) => row.path === example.pick);
  if (!pick) throw new Error(`Agent demo: searching "${example.word}" no longer finds ${example.pick}`);

  const fits = compareVersions(pick.minIOS, target) <= 0;
  const run = { ...example, target, matches, pick, fits };
  if (!fits) return run;

  const check = checkSource(readSource(pick.path), pick.name);
  if (!check.license || !check.preview) {
    throw new Error(`Agent demo: ${pick.name}.swift must start with "${LICENSE}" and end with its #Preview`);
  }
  return {
    ...run,
    file: { name: `${pick.name}.swift`, lines: check.lines, url: `${RAW_BASE}/Components/${pick.path}/${pick.name}.swift` },
  };
}

/** Replays every exchange of the demo against the repository at `root`. */
export function loadAgentDemo(root) {
  const tsv = readFileSync(join(root, 'components.tsv'), 'utf8');
  const readSource = (path) => readFileSync(join(root, 'Components', path, `${path.split('/')[1]}.swift`), 'utf8');
  return DEMO_EXAMPLES.map((example) => agentRun({ tsv, readSource, example, target: DEMO_TARGET }));
}
