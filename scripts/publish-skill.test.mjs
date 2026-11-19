import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { cpSync, existsSync, mkdtempSync, readFileSync, rmSync, statSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { afterEach, describe, it } from 'node:test';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const release = readFileSync(join(root, 'CHANGELOG.md'), 'utf8').match(/^## (\d+\.\d+\.\d+) - /m)[1];
const temporary = [];

afterEach(() => {
  for (const folder of temporary.splice(0)) rmSync(folder, { recursive: true, force: true });
});

function folder(prefix) {
  const path = mkdtempSync(join(tmpdir(), prefix));
  temporary.push(path);
  return path;
}

function build(repository = root) {
  const out = join(folder('skill-out-'), 'out');
  const result = spawnSync('sh', [join(repository, 'scripts/publish-skill.sh'), out], { encoding: 'utf8' });
  return { out, result };
}

function copyOfRepository() {
  const copy = folder('skill-repo-');
  for (const path of ['scripts/publish-skill.sh', 'CHANGELOG.md', 'LICENSE', 'skills/swiftui-blocks/SKILL.md', 'skill-distribution']) {
    cpSync(join(root, path), join(copy, path), { recursive: true });
  }
  return copy;
}

describe('the skill repository', () => {
  it('holds the skill, the manifests of every agent and the icon', () => {
    const { out, result } = build();

    assert.equal(result.status, 0, result.stderr);
    for (const file of [
      '.claude-plugin/icon.png',
      '.claude-plugin/marketplace.json',
      '.claude-plugin/plugin.json',
      'gemini-extension.json',
      'LICENSE',
      'README.md',
      'skills/swiftui-blocks/SKILL.md',
    ]) {
      assert.ok(existsSync(join(out, file)), `missing ${file}`);
    }
  });

  it('gives every manifest the version of the latest release', () => {
    const { out } = build();

    for (const file of ['.claude-plugin/plugin.json', 'gemini-extension.json']) {
      assert.equal(JSON.parse(readFileSync(join(out, file), 'utf8')).version, release, file);
    }
    assert.equal(JSON.parse(readFileSync(join(out, '.claude-plugin/marketplace.json'), 'utf8')).name, 'swiftuiblocks');
  });

  it('carries a square PNG icon the plugin directory accepts', () => {
    const { out } = build();
    const icon = join(out, '.claude-plugin/icon.png');
    const bytes = readFileSync(icon);

    assert.equal(bytes.subarray(1, 4).toString('latin1'), 'PNG');
    const width = bytes.readUInt32BE(16);
    assert.equal(bytes.readUInt32BE(20), width);
    assert.ok(width >= 512 && width <= 2048, `${width} px`);
    assert.ok(statSync(icon).size < 2 * 1024 * 1024);
  });

  it('stops when a manifest would keep its placeholder version', () => {
    const copy = copyOfRepository();
    const manifest = join(copy, 'skill-distribution/gemini-extension.json');
    writeFileSync(manifest, readFileSync(manifest, 'utf8').replace('"version": "0.0.0"', '"version":"0.0.0"'));

    const { result } = build(copy);

    assert.notEqual(result.status, 0);
    assert.match(result.stderr, /gemini-extension\.json/);
  });
});
