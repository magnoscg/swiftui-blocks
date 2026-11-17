#!/bin/sh
# Builds the distribution repository of the skill into a folder: the skill,
# the plugin manifests and the license. With --publish it clones
# magnoscg/swiftui-blocks-skill, replaces its files and sends a commit.
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
version=$(sed -n 's/^## \([0-9][0-9.]*\) - .*/\1/p' "$root/CHANGELOG.md" | head -1)
repository=${SKILL_REPOSITORY:-git@github.com:magnoscg/swiftui-blocks-skill.git}

build() {
  out=$1
  find "$out" -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +
  cp -R "$root/skill-distribution/." "$out/"
  mkdir -p "$out/skills/swiftui-blocks"
  cp "$root/skills/swiftui-blocks/SKILL.md" "$out/skills/swiftui-blocks/SKILL.md"
  cp "$root/LICENSE" "$out/LICENSE"
  sed -i.bak "s/\"version\": \"0.0.0\"/\"version\": \"$version\"/" "$out/.claude-plugin/plugin.json"
  rm "$out/.claude-plugin/plugin.json.bak"
}

case "${1:-}" in
  --publish)
    work=$(mktemp -d)
    git clone --quiet "$repository" "$work"
    build "$work"
    cd "$work"
    git add -A
    if git diff --cached --quiet; then
      echo "The skill repository already matches $version."
    else
      git commit --quiet -m "chore: publish the skill of SwiftUI Blocks $version"
      git push --quiet origin HEAD
      echo "Published the skill of SwiftUI Blocks $version."
    fi
    rm -rf "$work"
    ;;
  "")
    echo "usage: $0 <folder> | --publish" >&2
    exit 2
    ;;
  *)
    mkdir -p "$1"
    build "$1"
    echo "Built the skill repository of $version in $1."
    ;;
esac
