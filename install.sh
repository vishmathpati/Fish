#!/usr/bin/env bash
# ============================================================================
# install.sh — Fish one-liner entrypoint
#
# Usage (from inside a project root):
#   curl -fsSL https://raw.githubusercontent.com/<you>/Fish/main/install.sh | bash
#
# What it does:
#   1. Clones (or updates) Fish into ~/.fish
#   2. Runs scripts/setup-design-system.sh against the current directory
#
# Safe to re-run. If ~/.fish already exists, does a git pull instead of clone.
# ============================================================================

set -euo pipefail

FISH_REPO="${FISH_REPO:-https://github.com/vishmathpati/Fish.git}"
FISH_HOME="${FISH_HOME:-$HOME/.fish}"
PROJECT_ROOT="${1:-$PWD}"

GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'; BOLD=$'\033[1m'; RESET=$'\033[0m'

say()   { printf '%s\n' "$*"; }
ok()    { printf '  %s✓%s %s\n' "$GREEN" "$RESET" "$*"; }
warn()  { printf '  %s!%s %s\n' "$YELLOW" "$RESET" "$*"; }
fail()  { printf '  %s✗%s %s\n' "$RED" "$RESET" "$*"; exit 1; }

say ""
printf '%s🐟  Fish — design-system workflow installer%s\n' "$BOLD" "$RESET"
say ""

command -v git >/dev/null || fail "git is required."
command -v jq  >/dev/null || fail "jq is required. On macOS: brew install jq"

if [ -d "$FISH_HOME/.git" ]; then
  say "  Updating Fish at $FISH_HOME…"
  git -C "$FISH_HOME" pull --ff-only
  ok "Fish updated"
else
  say "  Cloning Fish to $FISH_HOME…"
  git clone --depth 1 "$FISH_REPO" "$FISH_HOME"
  ok "Fish cloned"
fi

SETUP="$FISH_HOME/scripts/setup-design-system.sh"
[ -x "$SETUP" ] || chmod +x "$SETUP"

say ""
say "  Running setup against: $PROJECT_ROOT"
say ""

bash "$SETUP" "$PROJECT_ROOT"
