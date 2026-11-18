import assert from 'node:assert/strict';
import { dirname, join } from 'node:path';
import { describe, it } from 'node:test';
import { fileURLToPath } from 'node:url';
import { agentRun, checkSource, iosName, loadAgentDemo, searchIndex } from './agent-demo.mjs';

const TSV = [
  'component\tminIOS\tshader\ttitle\tsummary\tkeywords',
  'Buttons/LikeBurstButton\t18.0\t-\tLike Burst Button\tA heart button that bursts.\tlike, heart',
  'Effects/FloatingReactionsEmitter\t18.0\t-\tFloating Reactions Emitter\tEmoji that float up.\treactions, hearts',
  'Glass/GlassToolStrip\t26.0\t-\tGlass Tool Strip\tA row of Liquid Glass tool buttons.\ttoolbar, glass',
  'Glass/GlassTagCloud\t26.0\t-\tGlass Tag Cloud\tTags on glass.\ttags, glass',
  'Buttons/ExpandingSearchButton\t18.0\t-\tExpanding Search Button\tA search field.\tsearch, Glass',
].join('\n') + '\n';

const HEADER = '// SPDX-License-Identifier: MIT\n// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors\n';

function swift(name, { header = HEADER, preview = `#Preview {\n    ${name}Demo()\n}\n` } = {}) {
  return `${header}\nimport SwiftUI\n\nstruct ${name}: View {\n    var body: some View { Text("") }\n}\n\n${preview}`;
}

const LIKE = { id: 'like', prompt: 'Add a like button that bursts into hearts', word: 'heart', pick: 'Buttons/LikeBurstButton' };
const GLASS = { id: 'glass', prompt: 'Group my editing tools in a Liquid Glass strip', word: 'glass', pick: 'Glass/GlassToolStrip' };

describe('searchIndex', () => {
  it('matches a word anywhere in a line, ignoring case, like grep -i -F', () => {
    const matches = searchIndex(TSV, 'GLASS');

    assert.deepEqual(matches.map((row) => row.path), ['Glass/GlassToolStrip', 'Glass/GlassTagCloud', 'Buttons/ExpandingSearchButton']);
  });

  it('never matches the header line', () => {
    assert.deepEqual(searchIndex(TSV, 'summary'), []);
  });

  it('reads the columns of a line', () => {
    const [row] = searchIndex(TSV, 'like burst');

    assert.deepEqual(row, {
      path: 'Buttons/LikeBurstButton',
      category: 'Buttons',
      name: 'LikeBurstButton',
      minIOS: '18.0',
      shader: '-',
      title: 'Like Burst Button',
      summary: 'A heart button that bursts.',
    });
  });
});

describe('checkSource', () => {
  it('counts lines the way wc -l does and finds the header and the preview', () => {
    const source = swift('LikeBurstButton');

    assert.deepEqual(checkSource(source, 'LikeBurstButton'), { lines: source.split('\n').length - 1, license: true, preview: true });
  });

  it('rejects a file without the license header or the closing preview', () => {
    const result = checkSource(swift('LikeBurstButton', { header: '// MIT\n', preview: '#Preview { Text("") }\n' }), 'LikeBurstButton');

    assert.equal(result.license, false);
    assert.equal(result.preview, false);
  });
});

describe('agentRun', () => {
  it('adds a component that fits the deployment target, with the counts read from the index', () => {
    const run = agentRun({ tsv: TSV, readSource: (path) => swift(path.split('/')[1]), example: LIKE, target: '18.0' });

    assert.deepEqual(run.matches.map((row) => row.path), ['Buttons/LikeBurstButton', 'Effects/FloatingReactionsEmitter']);
    assert.equal(run.pick.title, 'Like Burst Button');
    assert.equal(run.fits, true);
    assert.equal(run.file.name, 'LikeBurstButton.swift');
    assert.equal(run.file.lines, swift('LikeBurstButton').split('\n').length - 1);
  });

  it('adds nothing when the component needs a newer iOS than the app targets', () => {
    const run = agentRun({ tsv: TSV, readSource: () => { throw new Error('not read'); }, example: GLASS, target: '18.0' });

    assert.equal(run.fits, false);
    assert.equal(run.file, undefined);
    assert.equal(run.pick.minIOS, '26.0');
  });

  it('compares iOS versions as numbers, not as text', () => {
    const run = agentRun({ tsv: TSV.replace('26.0', '9.0'), readSource: (path) => swift(path.split('/')[1]), example: GLASS, target: '18.0' });

    assert.equal(run.fits, true);
  });

  it('fails when the component it picks is not among the matches of its word', () => {
    assert.throws(() => agentRun({ tsv: TSV, readSource: () => '', example: { ...LIKE, word: 'toolbar' }, target: '18.0' }), /LikeBurstButton/);
  });

  it('fails when the component it picks also needs a Metal file, which the demo does not show', () => {
    const tsv = TSV.replace('Buttons/LikeBurstButton\t18.0\t-', 'Buttons/LikeBurstButton\t18.0\tmetal');

    assert.throws(() => agentRun({ tsv, readSource: (path) => swift(path.split('/')[1]), example: LIKE, target: '18.0' }), /metal/);
  });

  it('fails when the file it would add lacks the license header or the closing preview', () => {
    const readSource = (path) => swift(path.split('/')[1], { preview: '}\n' });

    assert.throws(() => agentRun({ tsv: TSV, readSource, example: LIKE, target: '18.0' }), /#Preview/);
  });
});

describe('iosName', () => {
  it('drops a .0 and keeps any other minor version', () => {
    assert.deepEqual([iosName('26.0'), iosName('18.4'), iosName('18')], ['26', '18.4', '18']);
  });
});

describe('loadAgentDemo', () => {
  it('builds every example of the site from the repository', () => {
    const root = join(dirname(fileURLToPath(import.meta.url)), '..');

    const runs = loadAgentDemo(root);

    assert.ok(runs.length >= 2);
    assert.ok(runs.some((run) => run.fits) && runs.some((run) => !run.fits));
  });
});
