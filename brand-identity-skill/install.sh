#!/usr/bin/env bash
# Install the brand-identity skill into one or more agents' skills folders.
#   ./install.sh                 install into every agent folder that already exists
#   ./install.sh claude codex    install into the named agents (claude codex gemini hermes opencode cursor agents)
#   ./install.sh --project ...   install into ./<agent>/skills of the current directory instead of $HOME
#   ./install.sh --force ...     overwrite an existing install
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)/skills/brand-identity"
NAME="brand-identity"
base="$HOME"; force=0; targets=()

for a in "$@"; do
  case "$a" in
    --project) base="$PWD" ;;
    --force) force=1 ;;
    -h|--help) sed -n '2,6p' "$0"; exit 0 ;;
    *) targets+=("$a") ;;
  esac
done

dir_for() {
  case "$1" in
    claude)   echo "$base/.claude/skills" ;;
    codex)    echo "$base/.codex/skills" ;;
    gemini)   echo "$base/.gemini/skills" ;;
    hermes)   echo "$base/.hermes/skills" ;;
    opencode) echo "$base/.config/opencode/skills" ;;
    cursor)   echo "$base/.cursor/skills" ;;
    agents)   echo "$base/.agents/skills" ;;   # shared folder read by several agents
    *) return 1 ;;
  esac
}

if [ ${#targets[@]} -eq 0 ]; then
  for t in claude codex gemini hermes opencode cursor; do
    parent="$(dirname "$(dir_for "$t")")"
    if [ "$base" != "$PWD" ] && [ -d "$parent" ]; then targets+=("$t"); fi
  done
  [ ${#targets[@]} -eq 0 ] && targets=(agents)
fi

for t in "${targets[@]}"; do
  dest="$(dir_for "$t")" || { echo "unknown agent: $t" >&2; exit 1; }
  if [ -e "$dest/$NAME" ] && [ $force -eq 0 ]; then
    echo "skip   $t: $dest/$NAME exists (use --force to overwrite)"; continue
  fi
  mkdir -p "$dest"; rm -rf "$dest/$NAME"; cp -R "$SRC" "$dest/$NAME"
  echo "ok     $t: $dest/$NAME"
done
echo "Restart your agent session so it picks the skill up."
