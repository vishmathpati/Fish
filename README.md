# Fish 🐟

> A drop-in kit that turns Claude Code into a real product designer for any
> shadcn-based project. One skill, one setup script, one design system per
> project. No more "it works but the UI is horrible."

Fish is a thin **orchestrator**. It doesn't generate UI itself — it routes
every UI request through three battle-tested specialists and enforces a
design-system compliance check on the output:

- **UI/UX Pro Max** — the taste brain (161 rules, 67 UI styles, 161 palettes, 57 font pairings).
- **shadcn MCP** — the component catalog. Searches across every registry you opt into (Magic UI, Aceternity, shadcnblocks, Tremor, Kokonut, Origin) as one unified pool.
- **Emil Kowalski skill** — the motion refinement layer, invoked only when needed.

The orchestrator — the `ui-workflow` skill — enforces three rules that make
everything downstream sane:

1. No UI is generated before `DESIGN-SYSTEM.md` exists at project root.
2. No code is written until the user sees a plan with candidate components and says "yes".
3. Every generated file is reviewed against `DESIGN-SYSTEM.md` with a **PASS / WARN / FAIL** verdict.

---

## Quickstart

From inside your project root:

```bash
curl -fsSL https://raw.githubusercontent.com/vishmathpati/Fish/main/install.sh | bash
```

Or if you'd rather clone:

```bash
git clone https://github.com/vishmathpati/Fish.git ~/.fish
bash ~/.fish/scripts/setup-design-system.sh
```

The setup script is idempotent, asks before doing anything, and installs only
what's missing. Re-run it any time.

---

## What gets installed

### MCPs

| MCP | When | Purpose |
|---|---|---|
| **shadcn MCP** | Always | Cross-registry component search |

Registry-specific MCPs (Magic UI ships one) are installed only when you opt
into that registry during setup.

### Skills

| Skill | Where | Purpose |
|---|---|---|
| **UI/UX Pro Max** | `~/.claude/skills/` (global) | Taste brain — runs first on every request |
| **Emil Kowalski motion** | `~/.claude/skills/` (global) | Motion/interaction refinement |
| **ui-workflow** | `.claude/skills/` (per project) | Orchestrates the other two + shadcn MCP |

### Subagent

| Agent | Where | Purpose |
|---|---|---|
| **design-review** | `.claude/agents/` (per project) | Compliance reviewer. Reports violations only, never rewrites code. |

### Optional registries (opt-in per project)

**None are added by default.** During setup you're walked through each one
and pick only what the project actually needs. If a registry's URL isn't in
the config yet, the installer prompts you to paste it at opt-in time.

| Namespace | Name | Good for |
|---|---|---|
| `@magicui` | Magic UI | Animated / marketing components — beams, marquees, bento grids, particle backgrounds |
| `@aceternity` | Aceternity UI | Motion-heavy hero sections, 3D cards, timelines, sparkles |
| `@reui` | REUI | Composable primitives + data-table / form patterns |
| `@smoothui` | SmoothUI | Polished micro-interactions, animated card states |
| `@unlumen` | Unlumen UI | Luminous, typography-forward marketing kits |
| `@cardcn` | Cardcn | Card-focused compositions — stat / feature / pricing cards |
| `@shadcnstudio` | ShadcnStudio | Visual-composer studio blocks built on shadcn base |
| `@efferd` | efferd | User-added registry |
| `@cultui` | Cult UI | Opinionated, trend-forward components — bento grids, glass cards |
| `@kokonut` | Kokonut UI | Micro-interactions, buttons, badges, animated form fields |
| `@tremor` | Tremor | Data dashboards — charts, KPI cards, sparklines, filtered tables |

All eleven are equal peers. Pick zero, pick one, pick all — up to you per project.

### Per-project compatibility profiles (optional)

If a project has strong design constraints (e.g. Notion-minimal, glassmorphism-forbidden, no-gradients), you can encode a **compatibility profile** in `~/.fish/config/registries.json` under the `compatibility_profiles` key. The profile assigns each registry a verdict:

| Verdict | Meaning |
|---------|---------|
| `PRIMARY` | Always search — neutral baseline |
| `EXTEND` | Always search — extends PRIMARY |
| `STYLE_REFERENCE` | Search — visual variants only |
| `SELECTIVE` | Search but only return components in the `allowed` list |
| `DEPRIORITIZE` | Skip unless nothing found elsewhere |
| `DROP` | Never search — incompatible design philosophy |

When a profile exists for a project, the `ui-workflow` skill auto-filters searches at Phase 3 Step 3 — no manual vigilance required. The approval gate always shows which registries were searched and which were filtered out.

Produce a profile by generating `COMPONENT-CATALOG-FULL.md` (full inventory) + `COMPONENT-CATALOG-FILTERED.md` (curated decisions) with Cowork, then encoding the filter decisions into `registries.json`.

---

## How it works

### Phase 1 — Bootstrap check
On the first UI request in a project, the `ui-workflow` skill silently
verifies that `components.json`, shadcn MCP, Pro Max, Emil, and `DESIGN-SYSTEM.md`
are all present. If anything's missing, it tells you what to run. It never
auto-installs.

### Phase 2 — Classification
Every UI request is sorted into one of five types:

- **A — Fundamental** (button, input, card, modal, tabs, etc.)
- **B — Extraordinary** (bento grid, animated beam, particle background, etc.)
- **C — Composition** (pricing page, dashboard overview, onboarding flow)
- **D — Motion-only** ("make this slide in", "animate the modal")
- **E — Review** ("audit this file")

### Phase 3 — The main loop (Types A / B / C)
1. Pro Max plans first — outputs requirements in plain design language (no library names).
2. The skill scans for motion cues (explicit like "animate", implicit like "modal entrance").
3. **Registry compatibility filter** — if a profile exists for this project, registries are pre-filtered before search: DROP/DEPRIORITIZE registries are skipped, SELECTIVE registries are constrained to their allowed component lists. The active filter is shown in the approval gate.
4. shadcn MCP searches the filtered registry set, returning 3-5 candidates per requirement.
5. `DISCOVERIES.md` is scanned as a secondary source.
6. You see a single consolidated plan — approve, adjust, or cancel.
7. On approval: shadcn installs, Emil refines motion, files are written.
8. A compliance table runs against `DESIGN-SYSTEM.md` → PASS / WARN / FAIL.

### Full-site mode
Trigger phrases like "initialize project" or "design the whole site" make
Pro Max generate `DESIGN-PLAN.md` — one section per feature with
plain-language requirements. Approve the plan, then the skill walks features
one at a time (never batch-generates).

---

## Design preview

After setup, Fish places a live preview page at `app/design-preview/page.tsx`. Visit `/design-preview` in your running dev server to see every design token and component rendered in a realistic app layout — sidebar, stat cards, task table, forms, buttons, badges, loading states, typography — all driven by your actual CSS variables.

A floating **Design Token Playground** toolbar (bottom-right) lets you change the primary color, border radius, dark/light mode, and typography in real time without touching any files. Changes are not persisted — it's a decision tool, not a theme editor.

Delete the route when you're done, or keep it as a living reference. To regenerate it at any time, say `"show design preview"` in Claude Code.

---

## The artifacts Fish produces per project

```
your-project/
├── DESIGN-SYSTEM.md              ← The law. Tokens, rules, forbidden patterns.
├── DESIGN-PLAN.md                ← The map. One section per page/feature.
├── DISCOVERIES.md                ← Your curated catalog of one-off patterns.
├── app/design-preview/page.tsx   ← Live token playground. Delete when done.
├── COMPONENT-CATALOG-FULL.md     ← Full inventory of all components across all registries (optional, generated by Cowork).
├── COMPONENT-CATALOG-FILTERED.md ← Curated winners with reasoning (optional, generated by Cowork). Used as auto-filter in Phase 3.
└── .claude/
    ├── skills/ui-workflow/       ← The orchestrator
    └── agents/design-review.md   ← The compliance reviewer
```

Plus two config files Fish merges into (never overwrites):

- `components.json` — shadcn config + registries block
- `.mcp.json` — shadcn MCP + any opted-in MCP servers

---

## Talking to it (after setup)

You never invoke the skills directly. You just describe what you want and
`ui-workflow` handles classification and routing:

- **"Initialize design system for this project"** → Pro Max asks brand/tone questions and writes `DESIGN-SYSTEM.md`.
- **"Design the whole site"** → Pro Max writes `DESIGN-PLAN.md` after reading your `README.md` or asking for the feature list.
- **"Add a pricing page with three tiers"** → Type C flow: Pro Max plans, shadcn searches, you approve, code gets written and reviewed.
- **"Animate the modal entrance"** → Type D flow: goes straight to Emil.
- **"Audit file src/components/header.tsx"** → Type E flow: report only.

### Maintenance commands

| Say | Does |
|---|---|
| `refresh design system skill` | Re-checks setup |
| `update design system` | Pro Max helps edit `DESIGN-SYSTEM.md` |
| `update design plan` | Pro Max helps edit `DESIGN-PLAN.md` |
| `add registry <namespace>` | Opts into another registry |
| `remove registry <namespace>` | Removes a registry |
| `log a discovery` | Appends to `DISCOVERIES.md` |
| `audit file <path>` | Compliance review only |

---

## Repo layout

```
Fish/
├── README.md                     ← This file
├── LICENSE                       ← MIT
├── install.sh                    ← Curl-one-liner entrypoint
├── skill/
│   └── SKILL.md                  ← The ui-workflow orchestrator skill
├── templates/
│   ├── DESIGN-SYSTEM.template.md
│   ├── DESIGN-PLAN.template.md
│   ├── DISCOVERIES.template.md
│   └── design-review.agent.md
├── config/
│   └── registries.json           ← Curated registry list
└── scripts/
    └── setup-design-system.sh    ← Per-project installer
```

---

## Requirements

- Node 18+ (for npx / shadcn CLI)
- `jq` (for JSON merging). On macOS: `brew install jq`
- A Claude Code subscription (Max plan recommended for Pro Max's reasoning)
- A shadcn-compatible project (Next.js, Vite, Astro, Remix all work)

---

## FAQ

**Why "Fish"?** Because it's a thin, silver, quick-moving thing that swims
between other tools. And because every codename needs to be a noun.

**Do I need all six optional registries?** No. Most projects use zero or one.
Pick what you need; ignore the rest.

**What if I already have `components.json`?** Fish merges. It only appends
registries you opt into; it never overwrites your existing config.

**What if I already have a `DESIGN-SYSTEM.md`?** Fish leaves it untouched.
The orchestrator reads whatever's there and enforces it.

**Does this work without shadcn?** No. Fish is shadcn-native. If you're on
MUI, Chakra, or Mantine, this isn't for you.

**Does it auto-install Magic UI?** No. Nothing registry-specific is installed
by default. You opt in during setup (or later via `add registry @magicui`).

---

## License

MIT — see [LICENSE](./LICENSE).

---

## Credits

Fish stands on three shoulders:

- [UI/UX Pro Max](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) by nextlevelbuilder
- [Emil Kowalski motion skill](https://github.com/emilkowalski/skill)
- [shadcn](https://ui.shadcn.com) and the shadcn MCP

The orchestration layer, templates, and installer are original.
