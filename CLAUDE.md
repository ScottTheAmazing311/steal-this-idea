# Steal This Idea — Claude Code Instructions

## Project Overview

This is a podcast-to-landing-page pipeline for the **Steal This Idea** podcast. The podcast discusses business ideas in each episode. Your job is to read transcripts, extract the business ideas, and generate a landing page + business plan for each one.

## Directory Structure

```
steal-this-idea/
├── CLAUDE.md              ← You are here
├── fetch-transcripts.sh   ← Step 1: Fetches .md transcripts from YouTube URLs
├── rebuild-index.sh       ← Step 3: Rebuilds the gallery index.html from meta.json files
├── transcripts/           ← Input: .md transcript files (one per episode)
└── ideas/                 ← Output: you create these
    └── {slug}/
        ├── index.html     ← Landing page (you generate this)
        └── meta.json      ← Idea metadata (you generate this)
```

## Your Workflow

When asked to "process transcripts" or "process all transcripts":

### For each `.md` file in `transcripts/`:

**1. Read the transcript and extract each business idea discussed.**

Most episodes have 1 idea, some have 2-3. For EACH idea, determine:

- `slug` — kebab-case short name (e.g. `pet-sitting-coop`)
- `company_name` — a catchy, memorable startup name
- `tagline` — one punchy line, 8 words max
- `elevator_pitch` — 2-3 sentences: what it does, why it matters
- `problem` — the core problem (2-3 sentences)
- `solution` — how the company solves it (2-3 sentences)
- `target_market` — who the customers are
- `revenue_model` — how it makes money (be specific)
- `key_features` — array of 4 features
- `competitive_advantage` — what makes it defensible
- `market_size_estimate` — rough TAM with reasoning
- `go_to_market` — initial launch strategy (2-3 sentences)
- `risks` — array of 3 risks
- `year_one_milestones` — array of 3 milestones
- `startup_cost_range` — estimated range to MVP
- `category` — one of: SaaS, Marketplace, Consumer, Fintech, Health, Education, Hardware, Services, AI/ML, Other
- `vibe` — one of: bold, playful, premium, technical, earthy, minimal, retro
- `episode_url` — pull from the `source_url` in the transcript frontmatter if present

**2. Save `meta.json`** to `ideas/{slug}/meta.json` with all the fields above.

**3. Generate `index.html`** — a complete, self-contained landing page at `ideas/{slug}/index.html`.

### Landing Page Requirements

Each landing page must be a **single self-contained HTML file** with all CSS in a `<style>` tag. No external dependencies except Google Fonts and image URLs.

**Design principles:**
- Should look like a REAL, professionally designed startup landing page
- Choose a distinctive aesthetic matching the idea's "vibe" — NOT a generic template
- Use Google Fonts — pick something characterful (NOT Inter, Roboto, Arial, system fonts)
- Every idea should look visually different from the others
- Rich visual hierarchy, bold typography, atmospheric backgrounds
- Smooth CSS animations (use IntersectionObserver for scroll-triggered reveals)
- Fully mobile responsive
- **NO EMOJIS** — never use emoji HTML entities or Unicode emoji anywhere. Use CSS-styled icons, geometric shapes, or SVG instead.
- **NO EM-DASHES** — never use `&mdash;` or the `—` character. Use commas, semicolons, colons, periods, or restructure sentences.
- **IMAGE-HEAVY** — every landing page should use lots of stock photography from Unsplash (via direct URLs like `https://images.unsplash.com/photo-{id}?auto=format&fit=crop&w=800&q=80`). Use relevant lifestyle/product photos for hero backgrounds, section backgrounds, feature cards, and anywhere visual content adds impact. Every major section should have at least one image.

**Required sections:**
1. **HERO** — Company name, tagline, elevator pitch, decorative CTA button (non-functional)
2. **PROBLEM** — What pain point exists
3. **SOLUTION** — How this company fixes it
4. **FEATURES** — Key features in a visually interesting layout (grid, cards, etc.)
5. **MARKET** — Target market and opportunity size
6. **BUSINESS PLAN** — A clean, embedded business plan with:
   - Revenue Model
   - Go-to-Market Strategy
   - Competitive Advantage
   - Year One Milestones
   - Startup Cost Estimate
   - Key Risks
7. **FOOTER** — "This is a concept from the Steal This Idea podcast" with link to episode

**Additional elements:**
- A small "💡 Steal This Idea" badge/link in the top corner pointing to `../index.html`
- CTA buttons should look real but not actually do anything
- The Business Plan section should feel like a real document, not an afterthought

### After processing all transcripts:

Run `./rebuild-index.sh` to regenerate the gallery `index.html`.

## Processing Commands

- **Process all**: Read every `.md` in `transcripts/`, generate landing pages for each
- **Process one**: When given a specific filename, process just that transcript
- **Rebuild index**: Run `./rebuild-index.sh`

## Style Variety Guide

Vary these across landing pages so no two look the same:

| Vibe | Fonts (examples) | Colors | Feel |
|------|-------------------|--------|------|
| bold | Bebas Neue + Source Sans | High contrast, neon accents | Startup energy |
| playful | Fredoka + Nunito | Bright, warm, rounded | Fun and approachable |
| premium | Cormorant Garamond + Lato | Dark bg, gold accents | Luxury/exclusive |
| technical | JetBrains Mono + IBM Plex | Dark theme, green/blue | Developer/hacker |
| earthy | Libre Baskerville + Karla | Greens, creams, browns | Natural/sustainable |
| minimal | Syne + Work Sans | Monochrome + one accent | Clean, Swiss design |
| retro | Archivo Black + Space Grotesk | Retro palette, textures | Throwback/vintage |

These are starting points — get creative and make each page feel like its own brand.
