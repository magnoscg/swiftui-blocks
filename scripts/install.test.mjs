import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { describe, it } from 'node:test';
import { fileURLToPath } from 'node:url';
import { agentId, installAgents, installWays } from '../docs/src/lib/install.ts';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const page = readFileSync(join(root, 'docs/src/content/docs/install.mdx'), 'utf8');
const headings = [...page.matchAll(/^## (.+)$/gm)].map(([, title]) => title);

describe('/install/', () => {
  it('offers six agents, with the skills CLI for any agent first', () => {
    assert.deepEqual(
      installAgents.map((way) => way.label),
      ['Any agent', 'Claude Code', 'Codex', 'Copilot CLI', 'Gemini CLI', 'Cursor'],
    );
  });

  it('leaves the install box of the landing page with the five ways it shows', () => {
    assert.deepEqual(
      installWays.map((way) => way.label),
      ['Any agent', 'Claude Code', 'Codex', 'Copilot CLI', 'Gemini CLI'],
    );
  });

  it('gives every agent a command to run and one to keep it up to date', () => {
    for (const way of installAgents) {
      assert.ok(way.commands.length > 0, way.label);
      assert.ok(way.update.length > 0, way.label);
    }
  });

  it('installs Cursor with the tested skills CLI command of any agent', () => {
    const [anyAgent] = installAgents;
    const cursor = installAgents.find((way) => way.label === 'Cursor');

    assert.deepEqual(cursor?.commands, anyAgent.commands);
  });

  it('links each agent with its own hash, which no section of the page takes', () => {
    const ids = installAgents.map((way) => agentId(way.label));

    assert.equal(new Set(ids).size, ids.length);
    for (const id of ids) {
      assert.ok(id && id !== 'by-hand' && !headings.map(agentId).includes(id), id);
    }
  });

  it('orders its sections from picking an agent to the questions', () => {
    assert.deepEqual(headings, [
      'Pick your agent',
      'Then just ask',
      'Without installing anything',
      'Where it goes',
      'Troubleshooting',
      'Questions',
    ]);
  });
});
