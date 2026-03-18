#!/bin/zsh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
IDEAS_DIR="$SCRIPT_DIR/ideas"

command -v jq >/dev/null 2>&1 || { echo "jq is required"; exit 1; }

ALL_IDEAS="[]"
COUNT=0
for meta_file in "$IDEAS_DIR"/*/meta.json; do
  [[ -f "$meta_file" ]] || continue
  slug=$(basename "$(dirname "$meta_file")")

  # Try to extract hero image from the idea's index.html
  hero_img=""
  idea_html="$IDEAS_DIR/$slug/index.html"
  if [[ -f "$idea_html" ]]; then
    hero_img=$(grep -oE "https://images\.unsplash\.com/photo-[^'\"?)]*" "$idea_html" | head -1)
    if [[ -z "$hero_img" ]]; then
      hero_img=$(grep -oE "https://plus\.unsplash\.com/premium_photo-[^'\"?)]*" "$idea_html" | head -1)
    fi
  fi

  # Add hero_image to the JSON object
  enriched=$(jq --arg img "$hero_img" '. + {hero_image: $img}' "$meta_file")
  ALL_IDEAS=$(echo "$ALL_IDEAS" | jq --argjson idea "$enriched" '. + [$idea]')
  COUNT=$((COUNT + 1))
done

if [[ $COUNT -eq 0 ]]; then
  echo "No ideas found in $IDEAS_DIR"
  exit 1
fi

echo "Found $COUNT ideas. Rebuilding index..."

# Sort ideas alphabetically by company name
ALL_IDEAS=$(echo "$ALL_IDEAS" | jq 'sort_by(.company_name)')

# Build category filter buttons
CATEGORIES=$(echo "$ALL_IDEAS" | jq -r '[.[].category // "Other"] | unique | .[]')
FILTER_HTML="<button class=\"filter-btn active\" data-filter=\"all\">All <span class=\"filter-count\">$COUNT</span></button>"
while IFS= read -r cat; do
  [[ -z "$cat" ]] && continue
  cat_count=$(echo "$ALL_IDEAS" | jq --arg c "$cat" '[.[] | select(.category == $c)] | length')
  FILTER_HTML+="<button class=\"filter-btn\" data-filter=\"$cat\">$cat <span class=\"filter-count\">$cat_count</span></button>"
done <<< "$CATEGORIES"

# Build card HTML
CARDS_HTML=""
while IFS= read -r idea_line; do
  slug=$(echo "$idea_line" | jq -r '.slug')
  name=$(echo "$idea_line" | jq -r '.company_name')
  tagline=$(echo "$idea_line" | jq -r '.tagline')
  pitch=$(echo "$idea_line" | jq -r '.elevator_pitch' | sed 's/\xe2\x80\x94/ - /g' | cut -c1-200)
  category=$(echo "$idea_line" | jq -r '.category // "Other"')
  vibe=$(echo "$idea_line" | jq -r '.vibe // "bold"')
  hero_img=$(echo "$idea_line" | jq -r '.hero_image // ""')
  ep_url=$(echo "$idea_line" | jq -r '.episode_url // ""')
  ep_num=$(echo "$idea_line" | jq -r '.episode_number // 0')

  # Build card image style
  img_style=""
  if [[ -n "$hero_img" && "$hero_img" != "null" && "$hero_img" != "" ]]; then
    img_style="style=\"background-image:url('${hero_img}?auto=format&fit=crop&w=800&q=60')\""
  fi

  ep_link=""
  if [[ -n "$ep_url" && "$ep_url" != "null" && "$ep_url" != "" ]]; then
    ep_link="<a href=\"$ep_url\" target=\"_blank\" rel=\"noopener\" class=\"card-link ep-link\">Watch Episode</a>"
  fi

  # Truncate pitch with ellipsis
  if [[ ${#pitch} -ge 200 ]]; then
    pitch="${pitch}..."
  fi

  CARDS_HTML+="
      <article class=\"idea-card\" data-category=\"$category\" data-vibe=\"$vibe\" data-name=\"$(echo "$name" | tr '[:upper:]' '[:lower:]')\" data-ep=\"$ep_num\">
        <a href=\"ideas/$slug/index.html\" target=\"_blank\" class=\"card-img-link\">
          <div class=\"card-img vibe-$vibe\" $img_style>
            <div class=\"card-img-overlay\">
              <span class=\"card-vibe-tag\">$vibe</span>
            </div>
          </div>
        </a>
        <div class=\"card-body\">
          <div class=\"card-meta\">
            <span class=\"card-category\">$category</span>
          </div>
          <h2 class=\"card-title\"><a href=\"ideas/$slug/index.html\" target=\"_blank\">$name</a></h2>
          <p class=\"card-tagline\">$tagline</p>
          <p class=\"card-pitch\">$pitch</p>
          <div class=\"card-actions\">
            <a href=\"ideas/$slug/index.html\" target=\"_blank\" class=\"card-link page-link\">View Landing Page</a>
            $ep_link
          </div>
        </div>
      </article>"
done < <(echo "$ALL_IDEAS" | jq -c '.[]')

# Write the HTML
cat > "$SCRIPT_DIR/index.html" << 'INDEXEOF'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Steal This Idea - Business Ideas Worth Building</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Space+Mono:wght@400;700&family=DM+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
<style>
:root {
  --yellow: #F2B705;
  --yellow-light: #f5c623;
  --yellow-dim: rgba(242, 183, 5, 0.10);
  --black: #111111;
  --black-soft: #1a1a1a;
  --bg: #fafaf5;
  --surface: #ffffff;
  --surface-hover: #fffdf0;
  --border: #e8e4d8;
  --border-hover: #d4c9a8;
  --text: #111111;
  --text-muted: #555555;
  --text-dim: #888888;
  --accent: #111111;
  --accent-bg: var(--yellow);
  --radius: 14px;
  --radius-sm: 8px;
}

*, *::before, *::after { margin: 0; padding: 0; box-sizing: border-box; }

body {
  font-family: 'DM Sans', -apple-system, sans-serif;
  background: var(--bg);
  color: var(--text);
  min-height: 100vh;
  overflow-x: hidden;
  -webkit-font-smoothing: antialiased;
}

.container {
  max-width: 1240px;
  margin: 0 auto;
  padding: 0 28px;
  position: relative;
  z-index: 1;
}

/* HERO BANNER */
.hero-banner {
  background: var(--yellow);
  margin: 0 -28px;
  padding: 60px 28px 48px;
  text-align: center;
  position: relative;
  overflow: hidden;
}
.hero-banner::after {
  content: '';
  position: absolute;
  bottom: -2px;
  left: 0;
  right: 0;
  height: 6px;
  background: var(--black);
}

.logo-img {
  width: 120px;
  height: 120px;
  border-radius: 20px;
  margin-bottom: 20px;
  box-shadow: 0 8px 32px rgba(0,0,0,0.2);
}

/* HEADER */
header {
  padding: 0 0 48px;
  text-align: center;
}

h1 {
  font-family: 'Space Mono', monospace;
  font-size: clamp(2.4rem, 5.5vw, 3.6rem);
  font-weight: 700;
  line-height: 1.1;
  margin-bottom: 16px;
  color: var(--black);
}

.subtitle {
  font-size: 1.1rem;
  color: var(--black);
  opacity: 0.7;
  max-width: 560px;
  margin: 0 auto 32px;
  line-height: 1.65;
}

/* Stats row */
.stats-row {
  display: flex;
  justify-content: center;
  gap: 48px;
  margin-bottom: 24px;
}
.stat-item {
  text-align: center;
}

/* Listen links */
.listen-row {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
  flex-wrap: wrap;
}
.listen-label {
  font-family: 'Space Mono', monospace;
  font-size: 12px;
  font-weight: 700;
  color: var(--black);
  text-transform: uppercase;
  letter-spacing: 2px;
}
.listen-link {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 8px 16px;
  background: var(--black);
  color: var(--yellow);
  border-radius: 100px;
  text-decoration: none;
  font-family: 'Space Mono', monospace;
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 0.5px;
  transition: all 0.2s;
}
.listen-link:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 16px rgba(0,0,0,0.3);
}
.listen-link svg {
  width: 16px;
  height: 16px;
  fill: currentColor;
}
.stat-num {
  font-family: 'Space Mono', monospace;
  font-size: 2.4rem;
  font-weight: 700;
  color: var(--black);
  line-height: 1;
  margin-bottom: 4px;
}
.stat-label {
  font-size: 0.78rem;
  color: var(--black);
  opacity: 0.5;
  text-transform: uppercase;
  letter-spacing: 2px;
}

/* Search */
.search-bar {
  max-width: 480px;
  margin: 32px auto 32px;
  position: relative;
}
.search-bar input {
  width: 100%;
  padding: 14px 20px 14px 48px;
  background: var(--surface);
  border: 2px solid var(--border);
  border-radius: 100px;
  color: var(--text);
  font-family: 'DM Sans', sans-serif;
  font-size: 0.95rem;
  outline: none;
  transition: border-color 0.2s, box-shadow 0.2s;
}
.search-bar input::placeholder { color: var(--text-dim); }
.search-bar input:focus {
  border-color: var(--yellow);
  box-shadow: 0 0 0 3px var(--yellow-dim);
}
.search-icon {
  position: absolute;
  left: 18px;
  top: 50%;
  transform: translateY(-50%);
  width: 18px;
  height: 18px;
  color: var(--text-dim);
}

/* Filters */
.filters {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  justify-content: center;
  margin-bottom: 48px;
}
.filter-btn {
  font-family: 'Space Mono', monospace;
  font-size: 11px;
  padding: 8px 18px;
  border: 2px solid var(--border);
  border-radius: 100px;
  background: transparent;
  color: var(--text-muted);
  cursor: pointer;
  transition: all 0.2s;
  letter-spacing: 0.5px;
  display: inline-flex;
  align-items: center;
  gap: 6px;
}
.filter-btn:hover {
  border-color: var(--yellow);
  color: var(--black);
  background: var(--yellow-dim);
}
.filter-btn.active {
  background: var(--yellow);
  color: var(--black);
  border-color: var(--yellow);
  font-weight: 700;
}
.filter-count {
  font-size: 10px;
  opacity: 0.7;
}
.filter-btn.active .filter-count { opacity: 0.8; }

/* Controls row */
.controls-row {
  margin-bottom: 48px;
}

/* Sort controls */
.sort-controls {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  margin-top: 16px;
}
.sort-label {
  font-family: 'Space Mono', monospace;
  font-size: 11px;
  color: var(--text-dim);
  text-transform: uppercase;
  letter-spacing: 1px;
  margin-right: 4px;
}
.sort-btn {
  font-family: 'Space Mono', monospace;
  font-size: 11px;
  padding: 6px 14px;
  border: 2px solid var(--border);
  border-radius: 100px;
  background: transparent;
  color: var(--text-muted);
  cursor: pointer;
  transition: all 0.2s;
  letter-spacing: 0.5px;
}
.sort-btn:hover {
  border-color: var(--yellow);
  color: var(--black);
}
.sort-btn.active {
  background: var(--black);
  color: var(--yellow);
  border-color: var(--black);
  font-weight: 700;
}

/* No results */
.no-results {
  text-align: center;
  padding: 80px 20px;
  display: none;
}
.no-results h3 {
  font-family: 'Space Mono', monospace;
  font-size: 1.2rem;
  color: var(--text-muted);
  margin-bottom: 8px;
}
.no-results p {
  color: var(--text-dim);
  font-size: 0.95rem;
}

/* GRID */
.ideas-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(360px, 1fr));
  gap: 28px;
  padding-bottom: 80px;
}

/* CARDS */
.idea-card {
  background: var(--surface);
  border: 2px solid var(--border);
  border-radius: var(--radius);
  overflow: hidden;
  transition: all 0.35s ease;
  animation: fadeUp 0.5s ease both;
}
.idea-card:hover {
  border-color: var(--yellow);
  transform: translateY(-6px);
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.08);
}
.idea-card.hidden { display: none; }

@keyframes fadeUp {
  from { opacity: 0; transform: translateY(24px); }
  to { opacity: 1; transform: translateY(0); }
}

/* Card image */
.card-img-link { display: block; text-decoration: none; }
.card-img {
  width: 100%;
  height: 200px;
  background-size: cover;
  background-position: center;
  position: relative;
  transition: transform 0.5s ease;
}
.idea-card:hover .card-img { transform: scale(1.03); }

.card-img-overlay {
  position: absolute;
  inset: 0;
  background: linear-gradient(180deg, transparent 40%, rgba(0,0,0,0.7) 100%);
  display: flex;
  align-items: flex-end;
  justify-content: flex-start;
  padding: 16px;
}

.card-vibe-tag {
  font-family: 'Space Mono', monospace;
  font-size: 10px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 2px;
  padding: 4px 10px;
  border-radius: 4px;
  background: rgba(0, 0, 0, 0.5);
  backdrop-filter: blur(8px);
  color: #fff;
}

/* Vibe fallback gradients for cards without images */
.vibe-bold { background-color: #1a1020; background-image: linear-gradient(135deg, #2a1030 0%, #18182a 100%); }
.vibe-playful { background-color: #F2B705; background-image: linear-gradient(135deg, #f5c623 0%, #e8a800 100%); }
.vibe-premium { background-color: #1a1828; background-image: linear-gradient(135deg, #2a2040 0%, #101020 100%); }
.vibe-technical { background-color: #0c1420; background-image: linear-gradient(135deg, #0e1a2c 0%, #0a1218 100%); }
.vibe-earthy { background-color: #2a3520; background-image: linear-gradient(135deg, #354428 0%, #1e2a18 100%); }
.vibe-minimal { background-color: #e8e8e8; background-image: linear-gradient(135deg, #f0f0f0 0%, #d8d8d8 100%); }
.vibe-retro { background-color: #3a2820; background-image: linear-gradient(135deg, #4a3425 0%, #2a1e18 100%); }

/* Card body */
.card-body { padding: 24px 24px 28px; }

.card-meta {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 12px;
}

.card-category {
  font-family: 'Space Mono', monospace;
  font-size: 10px;
  font-weight: 700;
  color: var(--black);
  text-transform: uppercase;
  letter-spacing: 2px;
  padding: 3px 10px;
  background: var(--yellow);
  border-radius: 4px;
}

.card-title {
  font-family: 'Space Mono', monospace;
  font-size: 1.25rem;
  font-weight: 700;
  margin-bottom: 6px;
  line-height: 1.3;
}
.card-title a {
  color: var(--text);
  text-decoration: none;
  transition: color 0.2s;
}
.card-title a:hover { color: var(--accent); }

.card-tagline {
  font-size: 0.92rem;
  color: var(--text-muted);
  font-style: italic;
  margin-bottom: 12px;
  font-weight: 500;
}

.card-pitch {
  font-size: 0.88rem;
  color: var(--text-muted);
  line-height: 1.6;
  margin-bottom: 20px;
}

.card-actions {
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
}

.card-link {
  font-family: 'Space Mono', monospace;
  font-size: 11px;
  font-weight: 700;
  padding: 8px 18px;
  border-radius: var(--radius-sm);
  text-decoration: none;
  transition: all 0.2s;
  letter-spacing: 0.5px;
}

.page-link {
  background: var(--yellow);
  color: var(--black);
  font-weight: 700;
}
.page-link:hover {
  filter: brightness(1.05);
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(242, 183, 5, 0.3);
}

.ep-link {
  border: 2px solid var(--border);
  color: var(--text-muted);
}
.ep-link:hover {
  border-color: var(--yellow);
  color: var(--black);
  background: var(--yellow-dim);
}

/* FOOTER */
footer {
  text-align: center;
  padding: 40px 0 60px;
  color: var(--text-dim);
  font-size: 0.85rem;
  border-top: 2px solid var(--border);
}
footer a {
  color: var(--black);
  font-weight: 600;
  text-decoration: none;
}
footer a:hover { text-decoration: underline; }

/* Responsive */
@media (max-width: 768px) {
  .hero-banner { padding: 40px 20px 36px; }
  .logo-img { width: 90px; height: 90px; }
  h1 { font-size: 2rem; }
  .stats-row { gap: 32px; }
  .stat-num { font-size: 1.8rem; }
  .ideas-grid { grid-template-columns: 1fr; }
  .card-img { height: 180px; }
}

@media (max-width: 480px) {
  .container { padding: 0 16px; }
  .stats-row { gap: 24px; }
  .filters { gap: 6px; }
  .filter-btn { font-size: 10px; padding: 6px 12px; }
}
</style>
</head>
<body>
<div class="container">

<div class="hero-banner">
  <img src="https://cachedimages.podchaser.com/256x256/aHR0cHM6Ly9zdG9yYWdlLmJ1enpzcHJvdXQuY29tL2x6YTY2cWtraWp3bDgzY2tlem9razE0d3JwYWE%2FLmpwZz0%3D/aHR0cHM6Ly93d3cucG9kY2hhc2VyLmNvbS9pbWFnZXMvbWlzc2luZy1pbWFnZS5wbmc%3D" alt="Steal This Idea" class="logo-img">
  <h1>steal these ideas</h1>
  <p class="subtitle">Business ideas from the podcast, each one explored with a full landing page and business plan. If you love it, steal it.</p>
  <div class="stats-row">
    <div class="stat-item">
      <div class="stat-num">IDEA_COUNT_PLACEHOLDER</div>
      <div class="stat-label">Ideas</div>
    </div>
    <div class="stat-item">
      <div class="stat-num">CATEGORY_COUNT_PLACEHOLDER</div>
      <div class="stat-label">Categories</div>
    </div>
  </div>
  <div class="listen-row">
    <span class="listen-label">Listen to the show:</span>
    <a href="https://open.spotify.com/show/1AZ2Xbo8EAFm0k3vxkl5so" target="_blank" rel="noopener" class="listen-link">
      <svg viewBox="0 0 24 24"><path d="M12 0C5.4 0 0 5.4 0 12s5.4 12 12 12 12-5.4 12-12S18.66 0 12 0zm5.521 17.34c-.24.359-.66.48-1.021.24-2.82-1.74-6.36-2.101-10.561-1.141-.418.122-.779-.179-.899-.539-.12-.421.18-.78.54-.9 4.56-1.021 8.52-.6 11.64 1.32.42.18.479.659.301 1.02zm1.44-3.3c-.301.42-.841.6-1.262.3-3.239-1.98-8.159-2.58-11.939-1.38-.479.12-1.02-.12-1.14-.6-.12-.48.12-1.021.6-1.141C9.6 9.9 15 10.561 18.72 12.84c.361.181.54.78.241 1.2zm.12-3.36C15.24 8.4 8.82 8.16 5.16 9.301c-.6.179-1.2-.181-1.38-.721-.18-.601.18-1.2.72-1.381 4.26-1.26 11.28-1.02 15.721 1.621.539.3.719 1.02.419 1.56-.299.421-1.02.599-1.559.3z"/></svg>
      Spotify
    </a>
    <a href="https://podcasts.apple.com/us/podcast/steal-this-idea/id1472895373" target="_blank" rel="noopener" class="listen-link">
      <svg viewBox="0 0 24 24"><path d="M5.34 0A5.328 5.328 0 000 5.34v13.32A5.328 5.328 0 005.34 24h13.32A5.328 5.328 0 0024 18.66V5.34A5.328 5.328 0 0018.66 0H5.34zm6.525 2.568c2.336 0 4.448.902 6.056 2.587 1.224 1.272 1.912 2.619 2.264 4.392.12.6-.24 1.2-.84 1.32-.6.12-1.2-.24-1.32-.84-.264-1.272-.768-2.352-1.68-3.312-1.272-1.332-2.88-2.028-4.728-2.028-1.848 0-3.456.696-4.728 2.028-.888.936-1.416 2.04-1.68 3.312-.12.6-.72.96-1.32.84-.6-.12-.96-.72-.84-1.32.36-1.776 1.044-3.12 2.268-4.392 1.608-1.685 3.72-2.587 6.048-2.587zm.024 4.008c1.584 0 2.988.576 4.092 1.728.816.864 1.308 1.86 1.536 3.048.096.6-.312 1.164-.912 1.26-.6.096-1.164-.312-1.26-.912-.144-.756-.468-1.38-1.008-1.944-.732-.768-1.632-1.14-2.676-1.14-1.044 0-1.944.372-2.676 1.14-.54.564-.864 1.188-1.008 1.944-.096.6-.66 1.008-1.26.912-.6-.096-1.008-.66-.912-1.26.228-1.188.72-2.184 1.536-3.048 1.104-1.152 2.508-1.728 4.548-1.728zM12 10.8c1.32 0 2.4 1.08 2.4 2.4 0 .756-.348 1.392-.852 1.836l.696 3.708c.12.6-.312 1.164-.912 1.26a1.191 1.191 0 01-1.26-.912l-.072-.384-.072.384c-.096.6-.66 1.032-1.26.912-.6-.096-1.032-.66-.912-1.26l.696-3.708A2.376 2.376 0 019.6 13.2c0-1.32 1.08-2.4 2.4-2.4z"/></svg>
      Apple
    </a>
    <a href="https://www.youtube.com/@stealthisideapodcast463/podcasts" target="_blank" rel="noopener" class="listen-link">
      <svg viewBox="0 0 24 24"><path d="M23.498 6.186a3.016 3.016 0 00-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0-9.377.505A3.017 3.017 0 00.502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 3.016 0 002.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015 0 002.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814zM9.545 15.568V8.432L15.818 12l-6.273 3.568z"/></svg>
      YouTube
    </a>
  </div>
</div>
<header></header>

<div class="search-bar">
  <svg class="search-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
    <circle cx="11" cy="11" r="8"></circle>
    <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
  </svg>
  <input type="text" id="searchInput" placeholder="Search ideas...">
</div>

<div class="controls-row">
  <div class="filters">FILTERS_PLACEHOLDER</div>
  <div class="sort-controls">
    <span class="sort-label">Sort:</span>
    <button class="sort-btn active" data-sort="alpha">A to Z</button>
    <button class="sort-btn" data-sort="newest">Newest First</button>
    <button class="sort-btn" data-sort="oldest">Oldest First</button>
  </div>
</div>

<div class="no-results" id="noResults">
  <h3>No ideas match your search</h3>
  <p>Try a different keyword or clear the filters.</p>
</div>

<div class="ideas-grid" id="ideasGrid">CARDS_PLACEHOLDER</div>

<footer>
  <p>A project by the Steal This Idea Podcast. All ideas are free to use. Go build something.</p>
</footer>

</div>

<script>
(function() {
  var activeFilter = 'all';
  var searchTerm = '';
  var activeSort = 'alpha';
  var grid = document.getElementById('ideasGrid');

  function sortCards() {
    var cards = Array.from(grid.querySelectorAll('.idea-card'));
    cards.sort(function(a, b) {
      if (activeSort === 'newest') {
        return parseInt(b.dataset.ep || 0) - parseInt(a.dataset.ep || 0);
      } else if (activeSort === 'oldest') {
        return parseInt(a.dataset.ep || 0) - parseInt(b.dataset.ep || 0);
      } else {
        return (a.dataset.name || '').localeCompare(b.dataset.name || '');
      }
    });
    cards.forEach(function(card) { grid.appendChild(card); });
  }

  function filterCards() {
    var cards = grid.querySelectorAll('.idea-card');
    var visible = 0;
    cards.forEach(function(card, i) {
      var matchCategory = activeFilter === 'all' || card.dataset.category === activeFilter;
      var matchSearch = !searchTerm ||
        card.dataset.name.indexOf(searchTerm) !== -1 ||
        (card.querySelector('.card-tagline') && card.querySelector('.card-tagline').textContent.toLowerCase().indexOf(searchTerm) !== -1) ||
        (card.querySelector('.card-pitch') && card.querySelector('.card-pitch').textContent.toLowerCase().indexOf(searchTerm) !== -1) ||
        card.dataset.category.toLowerCase().indexOf(searchTerm) !== -1;
      var show = matchCategory && matchSearch;
      card.classList.toggle('hidden', !show);
      if (show) {
        card.style.animationDelay = (visible * 0.06) + 's';
        visible++;
      }
    });
    document.getElementById('noResults').style.display = visible === 0 ? 'block' : 'none';
  }

  // Filter buttons
  document.querySelectorAll('.filter-btn').forEach(function(btn) {
    btn.addEventListener('click', function() {
      document.querySelectorAll('.filter-btn').forEach(function(b) { b.classList.remove('active'); });
      btn.classList.add('active');
      activeFilter = btn.dataset.filter;
      filterCards();
    });
  });

  // Sort buttons
  document.querySelectorAll('.sort-btn').forEach(function(btn) {
    btn.addEventListener('click', function() {
      document.querySelectorAll('.sort-btn').forEach(function(b) { b.classList.remove('active'); });
      btn.classList.add('active');
      activeSort = btn.dataset.sort;
      sortCards();
      filterCards();
    });
  });

  // Search
  document.getElementById('searchInput').addEventListener('input', function(e) {
    searchTerm = e.target.value.toLowerCase().trim();
    filterCards();
  });

  // Initial stagger
  grid.querySelectorAll('.idea-card').forEach(function(c, i) {
    c.style.animationDelay = (i * 0.08) + 's';
  });
})();
</script>
</body>
</html>
INDEXEOF

# Count categories
CAT_COUNT=$(echo "$CATEGORIES" | wc -l | tr -d ' ')

# Replace placeholders
python3 << PYEOF
with open("$SCRIPT_DIR/index.html", "r") as f:
    content = f.read()
content = content.replace("IDEA_COUNT_PLACEHOLDER", "$COUNT")
content = content.replace("CATEGORY_COUNT_PLACEHOLDER", "$CAT_COUNT")
content = content.replace("FILTERS_PLACEHOLDER", """$FILTER_HTML""")
content = content.replace("CARDS_PLACEHOLDER", """$CARDS_HTML""")
with open("$SCRIPT_DIR/index.html", "w") as f:
    f.write(content)
PYEOF

echo "Gallery rebuilt: index.html ($COUNT ideas, $CAT_COUNT categories)"
echo "Preview: python3 -m http.server 8080"
