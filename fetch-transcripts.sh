#!/bin/zsh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TRANSCRIPTS_DIR="$SCRIPT_DIR/transcripts"

if [[ $# -lt 1 ]]; then
  echo "Usage: ./fetch-transcripts.sh <urls.txt>"
  exit 1
fi

URLS_FILE="$1"
[[ ! -f "$URLS_FILE" ]] && { echo "File not found: $URLS_FILE"; exit 1; }

mkdir -p "$TRANSCRIPTS_DIR"

URLS=()
while IFS= read -r line; do
  [[ -z "$line" || "$line" == \#* ]] && continue
  URLS+=("$line")
done < "$URLS_FILE"

TOTAL=${#URLS[@]}

echo ""
echo "  Steal This Idea — Transcript Fetcher"
echo "  Found $TOTAL URLs to process"
echo ""

SUCCESS=0
FAILED=0
num=0

for url in "${URLS[@]}"; do
  num=$((num + 1))

  video_id="episode-$num"
  if [[ "$url" =~ 'v=([a-zA-Z0-9_-]+)' ]]; then
    video_id="${match[1]}"
  fi

  echo "[$num/$TOTAL] Fetching: $url"

  # Strip https:// for defuddle URL format
  STRIPPED_URL="${url#https://}"
  STRIPPED_URL="${STRIPPED_URL#http://}"

  RESPONSE=$(curl -s -w "\n%{http_code}" "https://defuddle.md/$STRIPPED_URL" 2>/dev/null || echo "000")
  HTTP_CODE=$(echo "$RESPONSE" | tail -1)
  BODY=$(echo "$RESPONSE" | sed '$d')

  TITLE=""
  CONTENT=""

  if [[ "$HTTP_CODE" == "200" ]] && [[ -n "$BODY" ]] && [[ ${#BODY} -gt 100 ]]; then
    # Defuddle returns markdown with YAML frontmatter
    # Try to extract title from frontmatter
    TITLE=$(echo "$BODY" | sed -n 's/^title: *//p' | head -1)
    [[ -z "$TITLE" ]] && TITLE="Episode $num"
    CONTENT="$BODY"
  else
    # Fallback: use yt-dlp to grab auto-captions
    echo "  Defuddle failed, trying yt-dlp captions..."
    TITLE=$(yt-dlp --print "%(title)s" "$url" 2>/dev/null || echo "Episode $num")

    # Try to get English subtitles (auto-generated or manual)
    yt-dlp --write-auto-sub --write-sub --sub-lang en --sub-format vtt \
      --skip-download -o "$TRANSCRIPTS_DIR/temp-$video_id" "$url" 2>/dev/null

    VTT_FILE=$(ls "$TRANSCRIPTS_DIR"/temp-${video_id}*.vtt 2>/dev/null | head -1)

    if [[ -n "$VTT_FILE" && -f "$VTT_FILE" ]]; then
      # Convert VTT to plain text (strip timestamps and formatting)
      CONTENT=$(cat "$VTT_FILE" | grep -v '^WEBVTT' | grep -v '^Kind:' | grep -v '^Language:' | grep -v '^\s*$' | grep -v '^[0-9]' | grep -v '\-\->' | sed 's/<[^>]*>//g' | awk '!seen[$0]++')
      rm -f "$VTT_FILE"
    fi
  fi

  if [[ -n "$CONTENT" ]] && [[ ${#CONTENT} -gt 50 ]]; then
    SAFE_TITLE=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//' | cut -c1-80)
    [[ -z "$SAFE_TITLE" ]] && SAFE_TITLE="$video_id"

    OUTFILE="$TRANSCRIPTS_DIR/${SAFE_TITLE}.md"

    echo "---\nsource_url: $url\nvideo_id: $video_id\ntitle: $TITLE\n---\n\n$CONTENT" > "$OUTFILE"

    CHARS=$(echo "$CONTENT" | wc -c | tr -d ' ')
    echo "  [OK] Saved: $(basename "$OUTFILE") ($CHARS chars)"
    SUCCESS=$((SUCCESS + 1))
  else
    echo "  [FAIL] No content retrieved"
    FAILED=$((FAILED + 1))
  fi

  [[ $num -lt $TOTAL ]] && sleep 2
done

echo ""
echo "  Fetch complete!"
echo "  Succeeded: $SUCCESS"
echo "  Failed:    $FAILED"
echo "  Output:    $TRANSCRIPTS_DIR/"
echo ""
