---
title: For AI agents
description: How coding agents find a component and add its file to a project.
---

A coding agent finds a component in two small files and downloads its source,
so a lookup costs it a few thousand tokens. Every file here is generated from
the metadata of the components.

| File | What it has |
|---|---|
| [`llms.txt`](/llms.txt) | How to add a component, and every name by category. About 8 KB |
| [`components.tsv`](/components.tsv) | One tab-separated line per component: path, minimum iOS, shader, title, summary and keywords in English and Spanish. Made for `grep` |
| [`catalog.json`](/catalog.json) | Every component as data, for tools |
| [`llms-full.txt`](/llms-full.txt) | Every component with its full source. Large: an agent does not need it |

## Find and add a component

1. Search the index by a word, in English or Spanish:

   ```sh
   curl -fsSL https://swiftuiblocks.dev/components.tsv | grep -i "heart"
   ```

2. Compare its minimum iOS with the deployment target of the project.
3. Download the file instead of retyping it, keeping its license header:

   ```sh
   curl -fsSL -o LikeBurstButton.swift https://raw.githubusercontent.com/magnoscg/swiftui-blocks/HEAD/Components/Buttons/LikeBurstButton/LikeBurstButton.swift
   ```

4. If its shader column has a path, download that `.metal` file too, into the
   same target. The component draws nothing without it.

## Install the skill

The skill teaches your agent those steps, so you only ask for what you need:
*add a SwiftUI like button*. It is one file, and the agent reads it only when
you ask for a SwiftUI component.

Claude Code:

```sh
mkdir -p ~/.claude/skills/swiftui-blocks && curl -fsSL -o ~/.claude/skills/swiftui-blocks/SKILL.md https://raw.githubusercontent.com/magnoscg/swiftui-blocks/HEAD/skills/swiftui-blocks/SKILL.md
```

Codex, Cursor and Gemini CLI:

```sh
mkdir -p ~/.agents/skills/swiftui-blocks && curl -fsSL -o ~/.agents/skills/swiftui-blocks/SKILL.md https://raw.githubusercontent.com/magnoscg/swiftui-blocks/HEAD/skills/swiftui-blocks/SKILL.md
```

To add it to one project only, put the file in `.claude/skills/swiftui-blocks/`
or `.agents/skills/swiftui-blocks/` inside the project instead.

## Without an agent

Every component page has **Copy code** and **Download .swift**. Paste the code
into a new Swift file in your app target.

## Contribute

[AGENTS.md](https://github.com/magnoscg/swiftui-blocks/blob/HEAD/AGENTS.md) maps
the repository and lists the rules a change has to keep.
