#!/bin/sh
# Builds the distribution repository of the skill: the skill, the plugin
# manifests, the README and the license, with the version of the latest
# release in CHANGELOG.md.
#
#   scripts/publish-skill.sh <folder>   builds it into a new or empty folder
#   scripts/publish-skill.sh --publish  sends it to magnoscg/swiftui-blocks-skill,
#                                       from a clean release/X.Y.Z or hotfix/X.Y.Z branch
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
repository=${SKILL_REPOSITORY:-git@github.com:magnoscg/swiftui-blocks-skill.git}
version=$(sed -n 's/^## \([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\) - .*/\1/p' "$root/CHANGELOG.md" | head -1)

fail() {
  echo "publish-skill: $1" >&2
  exit 1
}

[ -n "$version" ] || fail "CHANGELOG.md has no release heading like '## 1.2.3 - 2026-01-31'."

# Writes the files of the distribution repository into $1, an empty folder or
# a fresh clone in a temporary folder.
build() {
  out=$1
  mkdir -p "$out/.claude-plugin" "$out/skills/swiftui-blocks"
  cp "$root/skill-distribution/.claude-plugin/marketplace.json" "$out/.claude-plugin/marketplace.json"
  cp "$root/skill-distribution/.claude-plugin/icon.png" "$out/.claude-plugin/icon.png"
  sed "s/\"version\": \"0.0.0\"/\"version\": \"$version\"/" \
    "$root/skill-distribution/.claude-plugin/plugin.json" > "$out/.claude-plugin/plugin.json"
  cp "$root/skill-distribution/README.md" "$out/README.md"
  cp "$root/LICENSE" "$out/LICENSE"
  cp "$root/skills/swiftui-blocks/SKILL.md" "$out/skills/swiftui-blocks/SKILL.md"
}

case "${1:-}" in
  --publish)
    branch=$(git -C "$root" rev-parse --abbrev-ref HEAD)
    [ "$branch" = "release/$version" ] || [ "$branch" = "hotfix/$version" ] ||
      fail "publish from release/$version or hotfix/$version, the version in CHANGELOG.md, not $branch."
    [ -z "$(git -C "$root" status --porcelain)" ] || fail "commit or stash your changes first."
    [ "$(git -C "$root" rev-parse HEAD)" = "$(git -C "$root" rev-parse '@{u}' 2>/dev/null || true)" ] ||
      fail "send $branch to GitHub first, so what you publish is what its pull request checked."
    work=$(mktemp -d)
    git clone --quiet -- "$repository" "$work"
    # The clone lives in its own temporary folder, so emptying it is safe, and a
    # file renamed or removed here does not linger in the repository.
    find "$work" -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +
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
