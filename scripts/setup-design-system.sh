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
#   7. Writes .mcp.json entries for shadcn MCP and any opted-in MCP servers
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
ask()   { local q="$1"; local d="${2:-n}"; local a; printf '  %s?%s %s [%s/%s] ' "$BLUE" "$RESET" "$q" "$([ "$d" = "y" ] && echo Y || echo y)" "$([ "$d" = "y" ] && echo n || echo N)"; read -r a; a="${a:-$d}"; [[ "$a" =~ ^[Yy]$ ]]; }

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
  if ask "Install UI/UX Pro Max globally via npm? (uipro-cli)" y; then
    npm install -g uipro-cli || fail "Failed to install uipro-cli."
    uipro init --ai claude || warn "uipro init returned non-zero — check the skill files under ~/.claude/skills/"
    HAS_PRO_MAX=1
    ok "UI/UX Pro Max installed"
  else
    warn "Skipped Pro Max — the ui-workflow skill will refuse to generate UI without it."
  fi
fi

if [ "$HAS_EMIL" = "0" ]; then
  if ask "Install Emil Kowalski motion skill?" y; then
    $PMX skills add emilkowalski/skill || warn "Emil install command returned non-zero — verify ~/.claude/skills/"
    HAS_EMIL=1
    ok "Emil motion skill installed"
  else
    warn "Skipped Emil — ui-workflow will skip motion refinement until this is installed."
  fi
fi

# ---------- registries (opt-in) -----------------------------------------------
head1 "4. Optional registries (opt-in)"

say "  None are added by default. Pick only what this project actually needs."
say ""

# Read opt-in candidates from config and present each
# shellcheck disable=SC2016
OPT_KEYS=$(jq -r '.optional | keys[]' "$REGISTRIES_CONFIG")

# NOTE: macOS ships Bash 3.2 — associative arrays (declare -A) don't exist.
# We use two parallel indexed arrays instead. SELECTED_KEYS[i] and
# SELECTED_URLS[i] describe the same registry.
SELECTED_KEYS=()
SELECTED_URLS=()
while IFS= read -r key; do
  name=$(jq   -r --arg k "$key" '.optional[$k].name'            "$REGISTRIES_CONFIG")
  url=$(jq    -r --arg k "$key" '.optional[$k].url'             "$REGISTRIES_CONFIG")
  best=$(jq   -r --arg k "$key" '.optional[$k].best_for'        "$REGISTRIES_CONFIG")
  src=$(jq    -r --arg k "$key" '.optional[$k].source // empty' "$REGISTRIES_CONFIG")
  notes=$(jq  -r --arg k "$key" '.optional[$k].notes // empty'  "$REGISTRIES_CONFIG")
  status=$(jq -r --arg k "$key" '.optional[$k].status // empty' "$REGISTRIES_CONFIG")

  say ""
  say "  ${BOLD}${key}${RESET} — ${name}"
  say "    ${DIM}${best}${RESET}"
  [ -n "$src" ] && say "    ${DIM}docs: ${src}${RESET}"

  # Non-registry entries (e.g. Tremor = npm-only) — show a notice, never merge
  if [ "$status" = "no_shadcn_registry" ]; then
    say "    ${YELLOW}Note:${RESET} ${notes}"
    if ask "    Open docs reference only (won't be added to components.json)?" n; then
      say "    ${DIM}Acknowledged — ${name} is available via its own install path, not through shadcn CLI.${RESET}"
    fi
    continue
  fi

  if ask "    Add ${key}?" n; then
    [ -n "$notes" ] && say "    ${DIM}${notes}${RESET}"
    SELECTED_KEYS+=("$key")
    SELECTED_URLS+=("$url")
  fi
done <<<"$OPT_KEYS"

# Merge selected registries into components.json
if [ ${#SELECTED_KEYS[@]} -gt 0 ]; then
  say ""
  ok "Merging ${#SELECTED_KEYS[@]} registries into components.json"
  TMP=$(mktemp)
  cp components.json "$TMP"
  for i in "${!SELECTED_KEYS[@]}"; do
    key="${SELECTED_KEYS[$i]}"
    url="${SELECTED_URLS[$i]}"
    jq --arg k "$key" --arg u "$url" \
       '.registries = (.registries // {}) | .registries[$k] = $u' \
       "$TMP" > "$TMP.new" && mv "$TMP.new" "$TMP"
  done
  mv "$TMP" components.json
  ok "components.json updated"
else
  miss "No registries selected. You can add later with: 'add registry <namespace>' (ui-workflow maintenance command)."
fi

# ---------- Claude assets ------------------------------------------------------
head1 "5. Install ui-workflow skill + agent + templates"

mkdir -p .claude/skills/ui-workflow
mkdir -p .claude/agents
cp "$SKILL_SRC" .claude/skills/ui-workflow/SKILL.md
ok ".claude/skills/ui-workflow/SKILL.md"

cp "$TEMPLATES_DIR/design-review.agent.md" .claude/agents/design-review.md
ok ".claude/agents/design-review.md"

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

# ---------- .mcp.json ---------------------------------------------------------
head1 "6. MCP configuration"

MCP_FILE=".mcp.json"
if [ ! -f "$MCP_FILE" ]; then
  echo '{"mcpServers": {}}' > "$MCP_FILE"
  ok "Created $MCP_FILE"
fi

# shadcn MCP — always add
TMP=$(mktemp)
jq '.mcpServers["shadcn"] = (.mcpServers["shadcn"] // {"command":"npx","args":["--yes","shadcn@latest","mcp"]})' \
   "$MCP_FILE" > "$TMP" && mv "$TMP" "$MCP_FILE"
ok "shadcn MCP registered"

# MCP for any selected registry that ships one (only Magic UI currently)
for key in "${SELECTED_REGISTRIES[@]}"; do
  HAS_MCP=$(jq -r --arg k "$key" '.optional[$k].mcp // empty' "$REGISTRIES_CONFIG")
  if [ -n "$HAS_MCP" ]; then
    CMD=$(jq -r --arg k "$key" '.optional[$k].mcp.command' "$REGISTRIES_CONFIG")
    ARGS=$(jq -c --arg k "$key" '.optional[$k].mcp.args'   "$REGISTRIES_CONFIG")
    SERVER_KEY="${key#@}"
    TMP=$(mktemp)
    jq --arg s "$SERVER_KEY" --arg c "$CMD" --argjson a "$ARGS" \
       '.mcpServers[$s] = {"command":$c,"args":$a}' \
       "$MCP_FILE" > "$TMP" && mv "$TMP" "$MCP_FILE"
    ok "$key MCP registered"
  fi
done

# ---------- summary ------------------------------------------------------------
head1 "7. Status"

printf '  %-35s %s\n' "Project root"         "$PROJECT_ROOT"
printf '  %-35s %s\n' "Package manager"      "$PM"
printf '  %-35s %s\n' "Framework"            "$FRAMEWORK"
printf '  %-35s %s\n' "components.json"      "$([ "$HAS_COMPONENTS_JSON" = "1" ] && echo yes || echo no)"
printf '  %-35s %s\n' "UI/UX Pro Max"        "$([ "$HAS_PRO_MAX" = "1" ] && echo yes || echo no)"
printf '  %-35s %s\n' "Emil motion skill"    "$([ "$HAS_EMIL" = "1" ] && echo yes || echo no)"
printf '  %-35s %s\n' "Registries selected"  "${#SELECTED_REGISTRIES[@]}"
[ ${#SELECTED_REGISTRIES[@]} -gt 0 ] && printf '  %-35s %s\n' "  - namespaces"          "${SELECTED_REGISTRIES[*]}"
printf '  %-35s %s\n' "ui-workflow skill"    ".claude/skills/ui-workflow/SKILL.md"
printf '  %-35s %s\n' "design-review agent"  ".claude/agents/design-review.md"
printf '  %-35s %s\n' "Templates placed"     "DESIGN-SYSTEM.template.md, DESIGN-PLAN.template.md, DISCOVERIES.template.md"

head1 "Next steps"

cat <<'EOS'
  1. Open Claude Code in this project. The ui-workflow skill is now active.
  2. Say:  "initialize design system for this project"
     → UI/UX Pro Max will ask brand/audience/tone questions, then write
       DESIGN-SYSTEM.md. Review and approve.
  3. For a full-site plan (multi-page):
     Say:  "design the whole site" or "initialize <project-name>"
     → Pro Max writes DESIGN-PLAN.md. Review and approve.
  4. For any single component/page after that, just describe what you want.
     ui-workflow will: classify → Pro Max plans → shadcn MCP searches →
     approval gate → execute → internal review.

  Maintenance commands (inside Claude Code):
    - "refresh design system skill"    (re-checks setup)
    - "update design system"           (edit DESIGN-SYSTEM.md via Pro Max)
    - "add registry <namespace>"       (opt into another registry)
    - "log a discovery"                (save a one-off pattern to DISCOVERIES.md)
    - "audit file <path>"              (compliance review only)

  Done.
EOS
