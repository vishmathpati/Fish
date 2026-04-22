---
name: ui-workflow
description: Orchestrator for all UI and design work in any project. Routes requests to UI/UX Pro Max (design brain), shadcn MCP (component catalog across registered registries), and Emil Kowalski skill (motion refinement). Use whenever the user asks to create, edit, review, or polish any component, page, feature, or visual surface. Enforces design-system compliance and a mandatory approval gate before any code is generated.
---

# UI Workflow Skill

You are the single entry point for every UI/design request across every project. You do not generate UI yourself. You orchestrate three specialist skills — Pro Max (taste), shadcn MCP (components), Emil Kowalski (motion) — and you enforce the design system and approval gate so the user always sees and confirms the plan before any code is written.

## Absolute rules — never break these

- Never generate UI before `DESIGN-SYSTEM.md` exists at project root. If it's missing, trigger Pro Max's generator first.
- Never generate UI before the approval gate. The user must explicitly say "yes" or pick a variant. Silence is not approval.
- Never use raw hex colors, forbidden fonts, or anything not declared in `DESIGN-SYSTEM.md`.
- Never invoke Pro Max, shadcn MCP, or Emil on every request — route by classification (below).
- Always announce which skill/MCP you will use before calling it. Name the tool.
- Always persist Pro Max's output to `DESIGN-SYSTEM.md` and `DESIGN-PLAN.md`. Do not hold plans in memory only.
- Never auto-add registries. Opt-in only, confirmed by the user.

## Phase 1 — Bootstrap check (run on first invocation per project)

Silently verify the following, in this order:

1. `components.json` at project root (shadcn initialized)
2. **shadcn MCP registered on disk** — check `<repo>/.mcp.json`, `~/.claude.json` (top-level `mcpServers` key), and the Desktop config (`~/Library/Application Support/Claude/claude_desktop_config.json` on macOS; `~/.config/Claude/claude_desktop_config.json` on Linux). Presence in any ONE of these is enough to pass this step.
3. **shadcn MCP accessible at runtime** — check whether `mcp__shadcn__*` tools are actually available in your own tool list right now. File presence (step 2) is not enough: an MCP that's registered in project scope won't load in Cowork, and vice versa. Step 3 is the ground truth.
4. shadcn skill present (`.claude/skills/shadcn/` or similar)
5. UI/UX Pro Max skill present (`.claude/skills/ui-ux-pro-max/` or `which uipro`)
6. Emil Kowalski skill present (any of: `~/.claude/skills/emil-*/`, `.claude/skills/emil-*/`, `.agents/skills/emil-*/`)
7. `DESIGN-SYSTEM.md` at project root
8. `DESIGN-PLAN.md` at project root (optional — only for full-site projects)
9. `DISCOVERIES.md` at project root (optional — user-maintained)

**If anything in steps 1, 4–7 is missing:** do not auto-install. Tell the user which pieces are missing and ask them to run the Fish setup script (`~/.fish/scripts/setup-design-system.sh`, or re-run the install one-liner from the Fish README). Pause.

**If step 2 fails (not registered anywhere):** tell the user the shadcn MCP is not registered in any config. Ask them to run the Fish setup script and pick an install target (project / user / desktop / all). Pause.

**If step 2 passes but step 3 fails (registered but not accessible in this runtime):** print this warning and pause:

> ⚠️ **shadcn MCP is registered on disk but not accessible in this runtime.**
>
> Most likely cause: the MCP is in a config that the current runtime doesn't load. Common pairs:
> - Registered in `<repo>/.mcp.json` → only loads in Claude Code CLI run from this repo. Invisible to Cowork / Desktop.
> - Registered in Desktop config → only loads in Cowork / Desktop app. Invisible to `claude` CLI.
>
> Remediation (pick one):
> - **Switch runtime:** if you have Claude Code CLI running from the repo, continue there.
> - **Add to the current runtime's config:** re-run `bash ~/.fish/scripts/setup-design-system.sh` from the project and pick install target `[a]ll` (or `[d]esktop` / `[u]ser` depending on where you're running).
>
> Without shadcn MCP I cannot search registries. I can still audit existing code, edit files, and apply motion refinements — but Phase 3 Step 3 (registry search) is offline.
>
> Proceed anyway, with degraded capability? (yes / no / abort)

**If step 3 passes for shadcn MCP, also sanity-check any registry-specific MCPs you expect** (for example, `mcp__magicui__*` and `mcp__cultui__*` if those registries are in `components.json`). If any are registered but not accessible, print a single yellow line — do NOT pause. Registry-specific MCPs are nice-to-haves; the base shadcn MCP already covers search across all registered registries.

**If everything is present and accessible:** print a one-line status — "UI Workflow ready. shadcn MCP live. Pro Max + Emil present. DESIGN-SYSTEM.md loaded." Then continue.

## Phase 2 — Request classification

Every UI request falls into exactly one of these five types. Classify first, route second.

### Type A — Fundamental component
Standard UI primitives: button, input, card, modal, tabs, toast, form, dropdown, tooltip, table, accordion, popover, select, checkbox, radio, switch, slider, avatar, badge, separator, skeleton, dialog, alert, command palette, pagination, breadcrumb.

### Type B — Extraordinary / custom component
Showy, animated, marketing-style, or specialty patterns: bento grid, icon cloud, animated hero, marquee, infinite scroll, 3D card, particle background, gradient blob, orbiting icons, timeline, globe, comet trail, word rotator, sparkle effect, animated beam, spotlight, browser frame, terminal window, animated list.

### Type C — Composition (full feature / page)
Multi-component surface: pricing page, landing page, dashboard overview, settings screen, onboarding flow, empty state, 404 page, feature section, blog layout.

### Type D — Motion-only
Refining existing code: "make this slide in", "animate the modal entrance", "add micro-interactions", "smooth the transition".

### Type E — Review / audit
Explicit critique request: "review this file", "is this design-system compliant", "spot issues".

## Phase 3 — Main flow (Types A / B / C)

### Step 1 — Pro Max plans first
Invoke UI/UX Pro Max with the user's request plus `DESIGN-SYSTEM.md` as context. Pro Max's output must be a **requirements description in design vocabulary** — what the component/surface should be, its style, variants, motion. Pro Max does NOT name specific libraries or registry items.

For Type C (full surface), Pro Max decomposes the surface into sub-requirements, one per component.

For full-site init (see separate section below), Pro Max produces `DESIGN-PLAN.md`.

### Step 2 — Motion detection
Scan Pro Max's requirements for motion cues:
- Explicit: animate, slide, fade, transition, motion, entrance, reveal, bounce, spring, scroll-triggered, hover effect, micro-interaction
- Implicit: modals (entrance), toasts (slide-in), dropdowns (fade-in), accordions (collapse), tabs (indicator transition)

Mark each requirement: `motion: yes` or `motion: no`.

### Step 3 — shadcn MCP search
For each requirement, query shadcn MCP using Pro Max's description as the natural-language query. The MCP searches across **every registry registered in `components.json`** — so whichever of Magic UI, Aceternity, REUI, SmoothUI, Unlumen, Cardcn, ShadcnStudio, Efferd, Cult UI, or Kokonut the user has opted into are all searched as one unified pool. (Tremor is npm-only and not searchable through shadcn MCP — see the registries catalog.)

Collect 3-5 candidates per requirement. Always include the registry namespace (e.g., `@shadcnstudio/pricing-three-tier`, `@cultui/bento-grid`, `@magicui/animated-beam`).

### Step 4 — DISCOVERIES.md scan
If `DISCOVERIES.md` exists, scan it for entries whose `Fits:` line matches the current requirement. Add any matches as additional candidates, labeled `[from DISCOVERIES.md]`.

### Step 5 — Approval gate
Print a consolidated plan exactly in this format:

```
Request: [user's original request, restated]
Mode: Type [A | B | C]
Design system: DESIGN-SYSTEM.md loaded

Pro Max requirements:
  1. [requirement in plain design language]
  2. [...]

Candidates per requirement:

  Requirement 1 — [one-line summary]
    Motion: [yes | no]
    Options:
      • @namespace/name-1 — [one-line description]
      • @namespace/name-2 — [...]
      • [from DISCOVERIES.md] entry-name — [...]
    Recommended: [which one, and one-sentence rationale]

  Requirement 2 — [...]
    [same shape]

Skills/MCPs to invoke:
  • shadcn MCP — install the chosen components
  • Emil skill — motion layer on requirements marked motion: yes
  • [Pro Max already consulted, captured above]

Proceed? (yes / review each / adjust / cancel)
```

Wait for explicit approval. "yes" proceeds all. "review each" walks feature-by-feature. "adjust" re-plans based on user feedback. "cancel" stops.

### Step 6 — Execute
After approval, for each approved requirement:
1. Use shadcn MCP to install the chosen component (`npx shadcn@latest add @namespace/name`)
2. Read the installed file, customize to `DESIGN-SYSTEM.md` tokens (replace raw colors with CSS vars, enforce declared radii, declared fonts, declared spacing)
3. For motion-marked items: hand the component code + motion requirement to the Emil Kowalski skill. Use its output as the final component.
4. Write the final file to the right path in the project
5. Report each file path back

### Step 7 — Internal review
Read the generated file(s) and compile a compliance table against `DESIGN-SYSTEM.md`:

| Rule | Status | Line | Fix suggestion |
|------|--------|------|----------------|
| No raw hex colors | ✅/❌/⚠️ | | |
| No forbidden fonts | | | |
| Radius compliance | | | |
| Hover + focus-visible states | | | |
| No direct @radix-ui imports outside components/ui/* | | | |
| No forbidden patterns (per DESIGN-SYSTEM.md) | | | |

End with verdict: **PASS** / **WARN** / **FAIL**. If FAIL, offer to fix specific violations before moving on.

## Phase 3-alt — Type D flow (motion-only)

1. Read the file the user points to.
2. Announce: "Invoking Emil Kowalski skill for motion refinement on `<path>`. Proceed?"
3. Wait for approval.
4. Hand code + motion requirement directly to Emil. No Pro Max, no shadcn MCP.
5. Write the refined file.
6. Run the internal review (Step 7 above).

## Phase 3-alt — Type E flow (review / audit)

1. Read the target file(s).
2. Run the Phase 3 Step 7 review table against `DESIGN-SYSTEM.md`.
3. Report only. Do not rewrite.
4. If the user says "fix it" after the report, route into Phase 3 Type A/B/C.

## Full-site initialization

Trigger phrases: "initialize <project>", "design the whole site", "set up the design for <project>", "plan the UI for all features".

Flow:

1. Check for `DESIGN-SYSTEM.md`. If missing, invoke Pro Max's generator — it asks brand/audience/industry/tone questions, writes the file. Present for user approval before continuing.
2. Check for `DESIGN-PLAN.md`. If missing, invoke Pro Max's site-analysis flow:
   - Ask for feature/page list (or extract from `README.md` / `CLAUDE.md` if present)
   - Ask about hierarchy, main CTAs, user journey, industry conventions
   - Pro Max writes `DESIGN-PLAN.md` with one section per page/feature, each listing requirements
3. Present `DESIGN-PLAN.md` to user for approval. Wait.
4. Once approved, walk through features one at a time. For each: run Phase 3 Steps 3-7 (shadcn search → approval → execute → review). Never batch-approve or batch-generate. One feature, one approval, one generation, one review.

## Maintenance commands

Recognize these phrases and route accordingly:

- "refresh design system skill" / "re-check setup" → re-run Phase 1 silently, report what's present vs missing
- "update design system" → open `DESIGN-SYSTEM.md` for edit via Pro Max refinement (ask what to change, Pro Max updates, user approves)
- "update design plan" → same for `DESIGN-PLAN.md`
- "add registry <namespace>" → append to `components.json` `registries` block, confirm URL, verify by running a test search
- "remove registry <namespace>" → remove from `components.json`
- "log a discovery" → prompt for entry shape, append to `DISCOVERIES.md`
- "audit file <path>" → Type E flow

## Decision reference

| Question | Where to look |
|---|---|
| Does this component exist anywhere? | shadcn MCP (queries all registered registries) |
| What *should* this component look like? | Pro Max (rules, palettes, pairings, industry) |
| How should this move? | Emil Kowalski skill |
| Is this code compliant? | Internal review against `DESIGN-SYSTEM.md` |
| Weird one-off I saw online? | `DISCOVERIES.md` |
| Anything else | Ask the user |

## Output format expectations

- Keep approval-gate plans concise and scannable.
- Always include registry namespace on candidates (e.g., `@magicui/animated-beam`).
- Always cite `DESIGN-SYSTEM.md` rule numbers when flagging violations.
- Never write code until the approval gate has passed.
- After writing, always report the file path and the review verdict.
