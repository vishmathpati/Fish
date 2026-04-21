# Discoveries

> Personal catalog of UI components, blocks, patterns, and ideas found outside
> the configured shadcn registries — blog posts, Figma community files, tweets,
> obscure repos, one-off demos. The `ui-workflow` skill scans this as a secondary
> source after querying shadcn MCP, so unusual patterns you've bookmarked can
> surface when a feature matches.
>
> Keep entries short. One entry per pattern. Update as you find things.

---

## Entry format

```
## [short-name-kebab-case]
Source: [library name OR URL OR "seen on X's site"]
What: [one-line description of what the pattern actually is]
Fits: [comma-separated list of use cases it suits — onboarding, empty states, hero, etc.]
URL: [direct link to code/demo if available]
Install: [command if it's installable, or "copy-paste"]
Notes: [anything else worth remembering]
```

---

## Example entries (delete these when you add your own)

## browser-frame
Source: Magic UI
What: A styled Chrome/Safari window chrome wrapping content
Fits: product demos, tutorial overlays, marketing screenshots, onboarding
URL: https://magicui.design/docs/components/browser-frame
Install: `npx shadcn@latest add @magicui/browser-frame`
Notes: Good for showing app previews on a landing page without full browser chrome.

## cursor-style-spotlight
Source: Seen on cursor.com
What: Soft radial spotlight that follows mouse on a dark hero
Fits: dark hero sections, high-contrast marketing pages
URL: https://cursor.com (view source)
Install: copy-paste, 20 lines of CSS + 10 lines of JS
Notes: Needs `prefers-reduced-motion` guard.

## stripe-pricing-tilt-card
Source: Seen on stripe.com/pricing
What: Pricing card that tilts slightly in 3D on hover
Fits: pricing pages, feature comparison cards
URL: —
Install: copy-paste, uses CSS transform perspective
Notes: Tilt angle is 4deg max — anything larger feels gimmicky.

---

<!-- Add your entries below this line -->
