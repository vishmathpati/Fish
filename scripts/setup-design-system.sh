#!/usr/bin/env bash
# ============================================================================
# setup-design-system.sh
#
# Bootstraps the UI Workflow in any Next.js / React project.
#
# What it does (in order):
#   1. Detects project state (package manager, framework, existing shadcn setup)
#   2. Checks what's already installed vs missing
#   3. Installs ONLY the foundation that's missing:
#        - shadcn CLI (init if components.json absent)
#        - UI/UX Pro Max skill
#        - Emil Kowalski motion skill
#   4. Prompts the user to opt into optional registries (Magic UI, Aceternity,
#      REUI, SmoothUI, Unlumen, Cardcn, ShadcnStudio, Efferd, Cult UI, Kokonut,
#      Tremor). None are added by default. The full catalog + URLs lives in
#      config/registries.json.
#   5. Merges opted-in registries into components.json
#   6. Copies the ui-workflow skill + agent + templates into .claude/
#   7. Writes MCP config entries for shadcn MCP and any opted-in MCP servers.
#      User picks target(s) at install time: project (.mcp.json) /
#      user (~/.claude.json) / desktop (claude_desktop_config.json) / all.
#      Each config is independent — installing to one does NOT cover the others.
#   8. Copies template files to the project root (DESIGN-SYSTEM.md is left
#      as .template.md so UI/UX Pro Max can fill it in on first real use)
#   9. Prints a status table + "next steps"
#
# Safe to re-run. Guards all existing files. Won't overwrite components.json
# or .mcp.json — merges instead.
# ============================================================================

set -euo pipefail

# ---------- paths --------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKFLOW_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILL_SRC="$WORKFLOW_ROOT/skill/SKILL.md"
TEMPLATES_DIR="$WORKFLOW_ROOT/templates"
REGISTRIES_CONFIG="$WORKFLOW_ROOT/config/registries.json"

# Project root defaults to current working directory. User can override.
PROJECT_ROOT="${1:-$PWD}"
cd "$PROJECT_ROOT"

# ---------- pretty output ------------------------------------------------------
BOLD=$'\033[1m'; DIM=$'\033[2m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'; BLUE=$'\033[34m'; RESET=$'\033[0m'
say()   { printf '%s\n' "$*"; }
head1() { printf '\n%s%s%s\n' "$BOLD" "$*" "$RESET"; }
ok()    { printf '  %s✓%s %s\n' "$GREEN" "$RESET" "$*"; }
warn()  { printf '  %s!%s %s\n' "$YELLOW" "$RESET" "$*"; }
miss()  { printf '  %s·%s %s\n' "$DIM" "$RESET" "$*"; }
fail()  { printf '  %s✗%s %s\n' "$RED" "$RESET" "$*"; exit 1; }
# Read from /dev/tty explicitly so prompts inside `while read` loops don't
# steal their input from the loop's stdin. (The registry opt-in loop feeds
# a heredoc of registry keys into stdin; without /dev/tty the prompts
# silently consume the next key as their answer.)
ask()   { local q="$1"; local d="${2:-n}"; local a; printf '  %s?%s %s [%s/%s] ' "$BLUE" "$RESET" "$q" "$([ "$d" = "y" ] && echo Y || echo y)" "$([ "$d" = "y" ] && echo n || echo N)"; read -r a </dev/tty; a="${a:-$d}"; [[ "$a" =~ ^[Yy]$ ]]; }

# ---------- tooling detection -------------------------------------------------
head1 "1. Detect project"

# package manager
if   [ -f "pnpm-lock.yaml" ]; then PM="pnpm"; PMX="pnpm dlx"
elif [ -f "yarn.lock" ];       then PM="yarn";  PMX="yarn dlx"
elif [ -f "bun.lockb" ];       then PM="bun";   PMX="bunx"
elif [ -f "package-lock.json" ];then PM="npm";  PMX="npx --yes"
elif [ -f "package.json" ];    then PM="npm";   PMX="npx --yes"
else fail "No package.json found at $PROJECT_ROOT. Run this from the project root."
fi
ok "Package manager: $PM"

# framework sniff (informational)
if   grep -q '"next"'   package.json 2>/dev/null; then FRAMEWORK="Next.js"
elif grep -q '"vite"'   package.json 2>/dev/null; then FRAMEWORK="Vite"
elif grep -q '"astro"'  package.json 2>/dev/null; then FRAMEWORK="Astro"
elif grep -q '"remix"'  package.json 2>/dev/null; then FRAMEWORK="Remix"
else FRAMEWORK="unknown"
fi
ok "Framework: $FRAMEWORK"

# required tools
command -v node >/dev/null || fail "node is not installed."
command -v git  >/dev/null || warn "git not found — skill files will be copied but version control tips won't run."
command -v jq   >/dev/null || fail "jq is required for JSON merging. Install with: brew install jq"

# ---------- foundation check ---------------------------------------------------
head1 "2. Foundation check"

HAS_COMPONENTS_JSON=0
[ -f "components.json" ] && HAS_COMPONENTS_JSON=1

HAS_PRO_MAX=0
command -v uipro >/dev/null 2>&1 && HAS_PRO_MAX=1
[ -d "$HOME/.claude/skills/ui-ux-pro-max" ] && HAS_PRO_MAX=1

HAS_EMIL=0
# Emil can land in a handful of places depending on which installer the user
# picked. Check all of them — the installer default is .agents/skills/ (project
# scope), but global ~/.claude/skills/ and local .claude/skills/ are also valid.
[ -d "$HOME/.claude/skills/emil-motion" ] && HAS_EMIL=1
[ -d "$HOME/.claude/skills/emil-kowalski" ] && HAS_EMIL=1
[ -d "$HOME/.claude/skills/emil-design-eng" ] && HAS_EMIL=1
ls "$HOME/.claude/skills/" 2>/dev/null | grep -qi emil && HAS_EMIL=1
# Project-scope installs from skills.sh land under .agents/ or .claude/
ls "./.agents/skills/" 2>/dev/null | grep -qi emil && HAS_EMIL=1
ls "./.claude/skills/" 2>/dev/null | grep -qi emil && HAS_EMIL=1

[ "$HAS_COMPONENTS_JSON" = "1" ] && ok "shadcn initialized (components.json present)" || miss "shadcn not initialized"
[ "$HAS_PRO_MAX"         = "1" ] && ok "UI/UX Pro Max installed"                        || miss "UI/UX Pro Max missing"
[ "$HAS_EMIL"            = "1" ] && ok "Emil motion skill installed"                    || miss "Emil motion skill missing"

# ---------- install missing foundation ----------------------------------------
head1 "3. Install missing foundation"

if [ "$HAS_COMPONENTS_JSON" = "0" ]; then
  if ask "Run 'shadcn init' now? (recommended defaults will be used)" y; then
    $PMX shadcn@latest init --yes --defaults || fail "shadcn init failed."
    HAS_COMPONENTS_JSON=1
    ok "shadcn initialized"
  else
    warn "Skipped shadcn init — re-run this script after you've initialized manually."
    exit 0
  fi
fi

if [ "$HAS_PRO_MAX" = "0" ]; then
  if ask "Install UI/UX Pro Max via Claude Code CLI?" y; then
    claude skills add nextlevelbuilder/ui-ux-pro-max-skill || warn "Pro Max install returned non-zero — install manually: https://github.com/nextlevelbuilder/ui-ux-pro-max-skill"
    HAS_PRO_MAX=1
    ok "UI/UX Pro Max installed"
  else
    warn "Skipped Pro Max — ui-workflow will refuse to generate UI without it."
  fi
fi

if [ "$HAS_EMIL" = "0" ]; then
  if ask "Install Emil Kowalski motion skill via Claude Code CLI?" y; then
    claude skills add emilkowalski/skill || warn "Emil install returned non-zero — verify ~/.claude/skills/ or .agents/skills/"
    HAS_EMIL=1
    ok "Emil motion skill installed"
  else
    warn "Skipped Emil — ui-workflow will skip motion refinement until this is installed."
  fi
fi

# ---------- registries (opt-in) -----------------------------------------------
# ---------- Claude assets ------------------------------------------------------
# Registries are selected AFTER the design system is initialized, not here.
# Once DESIGN-SYSTEM.md exists, the ui-workflow skill reads it and recommends
# which registries fit the project's aesthetic — with reasoning. The user picks
# from an informed position rather than guessing upfront.
head1 "4. Install ui-workflow skill + agent + templates"

mkdir -p .claude/skills/ui-workflow
mkdir -p .claude/agents
cp "$SKILL_SRC" .claude/skills/ui-workflow/SKILL.md
ok ".claude/skills/ui-workflow/SKILL.md"

cp "$TEMPLATES_DIR/design-review.agent.md" .claude/agents/design-review.md
ok ".claude/agents/design-review.md"

# Design preview page — copy to app/design-preview/page.tsx
# Gives an instant live preview of every design token + component before
# writing real features. Route: /design-preview. Safe to delete afterwards.
PREVIEW_DEST="app/design-preview/page.tsx"
if [ -f "$PREVIEW_DEST" ]; then
  miss "$PREVIEW_DEST already exists — leaving untouched"
else
  mkdir -p "app/design-preview"
  cp "$TEMPLATES_DIR/design-preview.template.tsx" "$PREVIEW_DEST"
  ok "$PREVIEW_DEST (visit /design-preview after starting dev server)"
fi

# Templates go to project root as .template.md — UI/UX Pro Max fills them on
# first real use (don't overwrite an already-populated DESIGN-SYSTEM.md).
for tpl in DESIGN-SYSTEM.template.md DESIGN-PLAN.template.md DISCOVERIES.template.md; do
  base="${tpl%.template.md}.md"
  if [ -f "$base" ]; then
    miss "$base already exists — leaving untouched"
  else
    cp "$TEMPLATES_DIR/$tpl" "$tpl"
    ok "$tpl (rename to $base when ready — UI/UX Pro Max will fill on first run)"
  fi
done

# ---------- MCP configuration (v0.2 — multi-target) ---------------------------
head1 "6. MCP configuration"

# MCPs live in different config files depending on the Claude runtime.
# None of these share state — installing to one does NOT cover the others.
#   p = project scope      — <repo>/.mcp.json         (claude CLI inside this repo)
#   u = user/global scope  — ~/.claude.json           (claude CLI anywhere)
#   d = desktop / Cowork   — claude_desktop_config    (Desktop app + Cowork)
case "$(uname -s)" in
  Darwin) DESKTOP_CONFIG="$HOME/Library/Application Support/Claude/claude_desktop_config.json" ;;
  Linux)  DESKTOP_CONFIG="$HOME/.config/Claude/claude_desktop_config.json" ;;
  *)      DESKTOP_CONFIG="" ;;
esac
USER_CONFIG="$HOME/.claude.json"
PROJECT_CONFIG="$PROJECT_ROOT/.mcp.json"

say "  MCPs can be installed into multiple Claude runtimes. They do NOT share config."
say ""
say "    ${BOLD}p${RESET}  project scope        ${DIM}${PROJECT_CONFIG}${RESET}"
say "       ${DIM}loaded when: 'claude' CLI is run inside this repo${RESET}"
say "    ${BOLD}u${RESET}  user/global scope    ${DIM}${USER_CONFIG}${RESET}"
say "       ${DIM}loaded when: 'claude' CLI is run anywhere on this machine${RESET}"
if [ -n "$DESKTOP_CONFIG" ]; then
  say "    ${BOLD}d${RESET}  desktop + Cowork     ${DIM}${DESKTOP_CONFIG}${RESET}"
  say "       ${DIM}loaded when: Claude Desktop app or Cowork session${RESET}"
fi
say ""
say "  Install targets: [${BOLD}p${RESET}]roject only · project+[${BOLD}u${RESET}]ser · project+[${BOLD}d${RESET}]esktop · [${BOLD}a${RESET}]ll · [${BOLD}s${RESET}]kip"
printf '  %s?%s Install targets [p]: ' "$BLUE" "$RESET"
read -r TARGETS </dev/tty
TARGETS="${TARGETS:-p}"

WRITE_PROJECT=0; WRITE_USER=0; WRITE_DESKTOP=0
case "$TARGETS" in
  s|S|skip)            miss "MCP registration skipped. Re-run this script to add later." ;;
  p|P|project)         WRITE_PROJECT=1 ;;
  u|U|user|pu|up)      WRITE_PROJECT=1; WRITE_USER=1 ;;
  d|D|desktop|pd|dp)   WRITE_PROJECT=1; WRITE_DESKTOP=1 ;;
  a|A|all)             WRITE_PROJECT=1; WRITE_USER=1; WRITE_DESKTOP=1 ;;
  *) warn "Unknown choice '$TARGETS' — defaulting to project only."; WRITE_PROJECT=1 ;;
esac

if [ "$WRITE_DESKTOP" = "1" ] && [ -z "$DESKTOP_CONFIG" ]; then
  warn "Desktop config path unknown on this OS — skipping desktop target."
  WRITE_DESKTOP=0
fi

# Helper — merge one MCP entry into a target JSON file. Non-clobbering:
# if .mcpServers[$key] already exists, leave it alone (respects user edits).
# Creates the file and parent dir if needed.
merge_mcp() {
  local file="$1" key="$2" cmd="$3" args_json="$4"
  local dir; dir="$(dirname "$file")"
  [ -d "$dir" ] || mkdir -p "$dir"
  if [ ! -f "$file" ]; then
    echo '{"mcpServers": {}}' > "$file"
  fi
  local TMP; TMP="$(mktemp)"
  jq --arg k "$key" --arg c "$cmd" --argjson a "$args_json" \
     '.mcpServers //= {} | .mcpServers[$k] = (.mcpServers[$k] // {"command":$c,"args":$a})' \
     "$file" > "$TMP" && mv "$TMP" "$file"
}

# register_mcp <key> <command> <args_json>  — write to every selected target
register_mcp() {
  local key="$1" cmd="$2" args_json="$3"
  local wrote=()
  if [ "$WRITE_PROJECT" = "1" ]; then merge_mcp "$PROJECT_CONFIG" "$key" "$cmd" "$args_json"; wrote+=("project"); fi
  if [ "$WRITE_USER"    = "1" ]; then merge_mcp "$USER_CONFIG"    "$key" "$cmd" "$args_json"; wrote+=("user"); fi
  if [ "$WRITE_DESKTOP" = "1" ]; then merge_mcp "$DESKTOP_CONFIG" "$key" "$cmd" "$args_json"; wrote+=("desktop"); fi
  if [ ${#wrote[@]} -gt 0 ]; then
    local joined; joined="$(IFS=,; echo "${wrote[*]}")"
    ok "$key MCP registered (${joined})"
  fi
}

if [ "$WRITE_PROJECT" = "1" ] || [ "$WRITE_USER" = "1" ] || [ "$WRITE_DESKTOP" = "1" ]; then
  # shadcn MCP — always add (required by ui-workflow skill)
  register_mcp "shadcn" "npx" '["--yes","shadcn@latest","mcp"]'

  # Registry-specific MCPs (Magic UI, Cult UI, etc.) are registered later —
  # after 'initialize design system' in Claude Code. The skill recommends
  # which registries fit the project and handles their MCP registration then.

  if [ "$WRITE_DESKTOP" = "1" ]; then
    say ""
    warn "Restart Claude Desktop app for desktop-scope MCPs to load."
  fi
fi

# ---------- summary ------------------------------------------------------------
head1 "7. Status"

printf '  %-35s %s\n' "Project root"         "$PROJECT_ROOT"
printf '  %-35s %s\n' "Package manager"      "$PM"
printf '  %-35s %s\n' "Framework"            "$FRAMEWORK"
printf '  %-35s %s\n' "components.json"      "$([ "$HAS_COMPONENTS_JSON" = "1" ] && echo yes || echo no)"
printf '  %-35s %s\n' "UI/UX Pro Max"        "$([ "$HAS_PRO_MAX" = "1" ] && echo yes || echo no)"
printf '  %-35s %s\n' "Emil motion skill"    "$([ "$HAS_EMIL" = "1" ] && echo yes || echo no)"
printf '  %-35s %s\n' "Registries"           "selected after design system init (see step 3 below)"
printf '  %-35s %s\n' "ui-workflow skill"    ".claude/skills/ui-workflow/SKILL.md"
printf '  %-35s %s\n' "design-review agent"  ".claude/agents/design-review.md"
printf '  %-35s %s\n' "Templates placed"     "DESIGN-SYSTEM.template.md, DESIGN-PLAN.template.md, DISCOVERIES.template.md"
printf '  %-35s %s\n' "Design preview"       "app/design-preview/page.tsx → visit /design-preview"

head1 "Next steps"

cat <<'EOS'
  1. Open Claude Code in this project. The ui-workflow skill is now active.

  2. Say:  "initialize design system for this project"
     → UI/UX Pro Max asks brand/audience/tone questions, writes DESIGN-SYSTEM.md.
       Review and approve.

  3. Say:  "recommend registries for this project"
     → ui-workflow reads your DESIGN-SYSTEM.md and recommends which component
       registries fit your aesthetic — with reasoning for each. You pick.
       Selected registries are merged into components.json automatically.

  4. Visit /design-preview in your running dev server.
     → See all your design tokens and components rendered live. Use the
       floating toolbar to tune primary color, radius, dark/light, and
       typography before writing a single real feature.

  5. For a full-site plan (multi-page):
     Say:  "design the whole site" or "initialize <project-name>"
     → Pro Max writes DESIGN-PLAN.md. Review and approve.

  6. For any component or page, just describe what you want.
     ui-workflow will: classify → Pro Max plans → shadcn MCP searches →
     approval gate → execute → compliance review.

  Maintenance commands (inside Claude Code):
    - "refresh design system skill"    (re-checks setup)
    - "update design system"           (edit DESIGN-SYSTEM.md via Pro Max)
    - "add registry <namespace>"       (opt into another registry anytime)
    - "log a discovery"                (save a one-off pattern to DISCOVERIES.md)
    - "audit file <path>"              (compliance review only)
    - "show design preview"            (reopen the live token playground)

  Done.
EOS
