#!/bin/sh
# Builds the distribution repository of the skill: the skill, the plugin
# manifests, the README and the license, with the version of the latest
# release in CHANGELOG.md.
#
#   scripts/publish-skill.sh <folder>   builds it into a new or empty folder
#   scripts/publish-skill.sh --publish  sends it to magnoscg/swiftui-blocks-skill,
#                                       from a clean release/X.Y.Z branch
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
repository=${SKILL_REPOSITORY:-git@github.com:magnoscg/swiftui-blocks-skill.git}
version=$(sed -n 's/^## \([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\) - .*/\1/p' "$root/CHANGELOG.md" | head -1)

fail() {
  echo "publish-skill: $1" >&2
  exit 1
}

[ -n "$version" ] || fail "CHANGELOG.md has no release heading like '## 1.2.3 - 2026-01-31'."

# Writes the files of the distribution repository into $1, which holds nothing
# but, when it is a clone, its .git folder and the files this writes.
build() {
  out=$1
  for file in .claude-plugin/marketplace.json .claude-plugin/plugin.json README.md LICENSE skills/swiftui-blocks/SKILL.md; do
    rm -f "$out/$file"
  done
  mkdir -p "$out/.claude-plugin" "$out/skills/swiftui-blocks"
  cp "$root/skill-distribution/.claude-plugin/marketplace.json" "$out/.claude-plugin/marketplace.json"
  sed "s/\"version\": \"0.0.0\"/\"version\": \"$version\"/" \
    "$root/skill-distribution/.claude-plugin/plugin.json" > "$out/.claude-plugin/plugin.json"
  cp "$root/skill-distribution/README.md" "$out/README.md"
  cp "$root/LICENSE" "$out/LICENSE"
  cp "$root/skills/swiftui-blocks/SKILL.md" "$out/skills/swiftui-blocks/SKILL.md"
}

case "${1:-}" in
  --publish)
    branch=$(git -C "$root" rev-parse --abbrev-ref HEAD)
    [ "$branch" = "release/$version" ] ||
      fail "publish from release/$version, the branch of the release in CHANGELOG.md, not $branch."
    [ -z "$(git -C "$root" status --porcelain)" ] || fail "commit or stash your changes first."
    work=$(mktemp -d)
    git clone --quiet -- "$repository" "$work"
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
  "" | -*)
    echo "usage: $0 <new or empty folder> | --publish" >&2
    exit 2
    ;;
  *)
    if [ -e "$1" ] && [ -n "$(ls -A "$1")" ]; then
      fail "$1 is not empty. Give a new or empty folder."
    fi
    mkdir -p "$1"
    build "$1"
    echo "Built the skill repository of $version in $1."
    ;;
esac
