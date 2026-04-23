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
10. `COMPONENT-CATALOG-FILTERED.md` at project root (optional — registry compatibility filter; if present, Step 3 will use it to auto-filter incompatible registries and components)
11. `COMPONENT-CATALOG-FULL.md` at project root (optional — full inventory reference; read-only reference, not used for filtering)

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

### Step 3 — Registry compatibility filter + shadcn MCP search

**Sub-step 3a — Load compatibility profile (run once per session)**

Before searching, check whether a compatibility profile exists for this project:

1. Look for `~/.fish/config/registries.json` → read the `compatibility_profiles` block.
2. Match the current project by folder name (e.g., `arel-dashboard`).
3. If a profile is found, load it. If not, default to searching all registered registries (no filter).
4. Also check for `COMPONENT-CATALOG-FILTERED.md` at project root. If present, it is the ground truth for filtered decisions — surface it to the approval gate as context.

**Sub-step 3b — Build the active registry list**

From the loaded profile, classify registries into three tiers:

| Tier | Verdict values | Search behavior |
|------|---------------|-----------------|
| **Search freely** | `PRIMARY`, `EXTEND`, `STYLE_REFERENCE` | Include in all searches with no restrictions |
| **Search selectively** | `SELECTIVE` | Include in search but constrain to the `allowed` component list only. Do not surface components outside that list even if they match. |
| **Do not search** | `DROP`, `DEPRIORITIZE` | Exclude entirely from this search. `DEPRIORITIZE` may be queried as a last resort only if no result found in higher tiers. |

Print the active registry list at the start of the approval gate so the user can see what was searched and what was filtered out.

**Sub-step 3c — Execute filtered search**

Query shadcn MCP using Pro Max's description as the natural-language query, constrained to the active registry list from 3b.

- For `SELECTIVE` registries: after retrieving results, discard any component whose name is not in the `allowed` list for that registry. Surface only allowed matches.
- If a `SELECTIVE` registry returns no allowed matches, state "no compatible match in @registry" — do not fall back to a disallowed component from that registry.
- If `DROP` registries would have relevant components, note them as "filtered out — incompatible design philosophy" in the approval gate. Do not offer them as options. The user may override by explicitly naming a registry, but Fish does not proactively suggest filtered items.

Collect 3-5 candidates per requirement across the unfiltered + selectively-filtered pool. Always include the registry namespace (e.g., `@reui/stepper`, `@cultui/direction-aware-tabs`, `@smoothui/motion-accordion`).

**Sub-step 3d — Flag any result from a SELECTIVE registry**

When a candidate comes from a `SELECTIVE` registry (not PRIMARY/EXTEND), append a note in the approval gate: `[selective — allowed per COMPONENT-CATALOG-FILTERED.md]`. This keeps the user aware of what's been approved vs. what's the open pool.

### Step 4 — DISCOVERIES.md scan
If `DISCOVERIES.md` exists, scan it for entries whose `Fits:` line matches the current requirement. Add any matches as additional candidates, labeled `[from DISCOVERIES.md]`.

### Step 5 — Approval gate
Print a consolidated plan exactly in this format:

```
Request: [user's original request, restated]
Mode: Type [A | B | C]
Design system: DESIGN-SYSTEM.md loaded
Registry filter: [active profile name, e.g. "arel-dashboard"] | Searching: [@shadcn @reui @shadcnstudio + selective: @smoothui @cultui @kokonut @unlumen @magicui] | Excluded: [@aceternity @efferd]

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

## Registry recommendation (trigger: "recommend registries" / "which registries should I use" / end of design system init)

Run this automatically after `DESIGN-SYSTEM.md` is approved — and any time the user asks explicitly.

1. Read `DESIGN-SYSTEM.md`. Extract: tone, aesthetic references, forbidden patterns, industry.
2. Read `~/.fish/config/registries.json` (or `$WORKFLOW_ROOT/config/registries.json`). Load the `optional` block.
3. For each registry, evaluate fit against the design system. Assign a preliminary verdict:
   - **Recommended** — aesthetic aligns, components will be useful for this project type
   - **Selective** — has some useful components but also many that conflict; note which categories to use
   - **Skip** — design philosophy conflicts with the declared aesthetic (e.g. glassmorphism registry for a minimal app)
4. Present a recommendation table in this format:

```
Registry recommendations for: [PROJECT_NAME]
Based on: DESIGN-SYSTEM.md (tone: X, aesthetic: Y, forbidden: Z)

  ✅ @shadcn        — Recommended. Neutral baseline, always include.
  ✅ @reui          — Recommended. Same philosophy as shadcn, strong data/form patterns.
  ⚠️  @smoothui     — Selective. Motion components fit; skip text animations and background effects.
  ⚠️  @magicui      — Selective. File tree, code comparison, dot/grid patterns fit; skip all text animations and backgrounds.
  ❌ @aceternity    — Skip. Heavy parallax and glassmorphism conflict with your minimal aesthetic.
  ❌ @efferd        — Skip. Marketing sections only, no individual primitives.
  [etc.]

Add recommended registries to components.json? (yes / review each / skip)
```

5. On "yes": merge all Recommended registries into `components.json` automatically. For Selective registries, ask one by one. Skip registries are not added.
6. For any registry that ships an MCP server (Magic UI, Cult UI): after adding to `components.json`, ask "Also register [registry] MCP?" and run the registration if yes.
7. Confirm final `components.json` registries block to the user.

**Never run registry recommendation before `DESIGN-SYSTEM.md` exists.** If missing, say "Initialize the design system first (`initialize design system for this project`), then I can recommend registries."

---

## Full-site initialization

Trigger phrases: "initialize <project>", "design the whole site", "set up the design for <project>", "plan the UI for all features".

Flow:

1. Check for `DESIGN-SYSTEM.md`. If missing, invoke Pro Max's generator — it asks brand/audience/industry/tone questions, writes the file. Present for user approval before continuing.
2. After `DESIGN-SYSTEM.md` is approved, run the Registry recommendation flow above. Wait for user to confirm registries before proceeding.
3. Check for `DESIGN-PLAN.md`. If missing, invoke Pro Max's site-analysis flow:
   - Ask for feature/page list (or extract from `README.md` / `CLAUDE.md` if present)
   - Ask about hierarchy, main CTAs, user journey, industry conventions
   - Pro Max writes `DESIGN-PLAN.md` with one section per page/feature, each listing requirements
4. Present `DESIGN-PLAN.md` to user for approval. Wait.
5. Once approved, walk through features one at a time. For each: run Phase 3 Steps 3-7 (shadcn search → approval → execute → review). Never batch-approve or batch-generate. One feature, one approval, one generation, one review.

## Maintenance commands

Recognize these phrases and route accordingly:

- "refresh design system skill" / "re-check setup" → re-run Phase 1 silently, report what's present vs missing
- "update design system" → open `DESIGN-SYSTEM.md` for edit via Pro Max refinement (ask what to change, Pro Max updates, user approves)
- "update design plan" → same for `DESIGN-PLAN.md`
- "recommend registries" / "which registries should I use" → run Registry recommendation flow (requires DESIGN-SYSTEM.md)
- "add registry <namespace>" → append to `components.json` `registries` block, confirm URL, verify by running a test search
- "remove registry <namespace>" → remove from `components.json`
- "log a discovery" → prompt for entry shape, append to `DISCOVERIES.md`
- "audit file <path>" → Type E flow
- "show design preview" / "open design preview" → remind user to visit `/design-preview` in the running dev server. If `app/design-preview/page.tsx` is missing, offer to copy it from `~/.fish/templates/design-preview.template.tsx`.

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
