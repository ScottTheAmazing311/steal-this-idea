# 💡 Steal This Idea

A pipeline that turns podcast episode transcripts into polished startup landing pages — no API key needed. Uses Claude Code to do the thinking.

## The Pipeline

```
YouTube URLs → fetch-transcripts.sh → .md files → Claude Code → landing pages → rebuild-index.sh → gallery site
```

### Step 1: Fetch Transcripts
```bash
./fetch-transcripts.sh urls.txt
```
Takes a list of YouTube URLs, fetches each transcript as markdown via [Defuddle](https://md.defuddle.com), saves to `transcripts/`.

### Step 2: Let Claude Code Do the Work
```bash
claude
```
Then tell it:
> Read the CLAUDE.md and process all transcripts

Claude Code reads each transcript, extracts the business ideas, generates a unique landing page with embedded business plan for each one, and saves everything to `ideas/`.

### Step 3: Rebuild the Gallery
```bash
./rebuild-index.sh
```
Scans all `ideas/*/meta.json` files and generates the central `index.html` gallery with category filtering.

### Preview
```bash
python3 -m http.server 8080
# Open http://localhost:8080
```

## Setup

**Requirements:**
- `curl`, `jq`, `python3` (all standard on macOS/Linux)
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed

**Install:**
```bash
# Clone or download this folder
cd steal-this-idea

# Make scripts executable (already done if you downloaded the release)
chmod +x fetch-transcripts.sh rebuild-index.sh
```

## File Structure

```
steal-this-idea/
├── CLAUDE.md               # Instructions Claude Code reads automatically
├── fetch-transcripts.sh    # Step 1: YouTube → markdown transcripts
├── rebuild-index.sh        # Step 3: Rebuild gallery from meta.json files
├── urls.txt                # Your list of YouTube episode URLs
├── index.html              # Auto-generated gallery site
├── transcripts/            # .md transcripts (auto-populated by Step 1)
└── ideas/                  # Generated output (created by Claude Code)
    └── {slug}/
        ├── index.html      # Landing page with embedded business plan
        └── meta.json       # Structured idea metadata
```

## Processing Tips

- You can process all transcripts at once or ask Claude to do one at a time
- Each landing page gets a unique visual identity — no two look the same
- Re-processing a transcript overwrites that idea's folder (idempotent)
- The gallery fully rebuilds from meta.json files, so it's always in sync
- For 100 episodes, you might want to batch in groups of 10-20 to keep Claude Code sessions manageable

## Hosting

The output is entirely static HTML. Deploy anywhere:
- **GitHub Pages** — push the repo, enable Pages
- **Netlify / Vercel** — point at the repo, zero config
- **Any web server** — just serve the folder

## Cost

**$0 in API fees.** The transcript fetching uses free services, and Claude Code does the analysis and generation directly. You just need a Claude Code subscription.
