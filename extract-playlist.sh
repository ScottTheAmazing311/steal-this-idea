#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if ! command -v yt-dlp >/dev/null 2>&1; then
  echo "ERROR: yt-dlp is required. Install with: brew install yt-dlp"
  exit 1
fi

if [[ $# -lt 1 ]]; then
  echo "Usage: ./extract-playlist.sh <playlist_url>"
  exit 1
fi

PLAYLIST_URL="$1"
OUTPUT_FILE="$SCRIPT_DIR/urls.txt"

echo ""
echo "  Extracting video URLs from playlist..."
echo ""

yt-dlp \
  --flat-playlist \
  --print "https://www.youtube.com/watch?v=%(id)s" \
  "$PLAYLIST_URL" > "$OUTPUT_FILE.tmp" 2>/dev/null

COUNT=$(wc -l < "$OUTPUT_FILE.tmp" | tr -d ' ')

if [[ $COUNT -eq 0 ]]; then
  echo "ERROR: No videos found. Check the URL and make sure the playlist is public."
  rm -f "$OUTPUT_FILE.tmp"
  exit 1
fi

{
  echo "# Steal This Idea — Episode URLs"
  echo "# Extracted from playlist on $(date +%Y-%m-%d)"
  echo "# Total: $COUNT videos"
  echo "#"
  cat "$OUTPUT_FILE.tmp"
} > "$OUTPUT_FILE"

rm -f "$OUTPUT_FILE.tmp"

echo "  Done! Extracted $COUNT video URLs → urls.txt"
echo ""
head -n 9 "$OUTPUT_FILE" | grep -v '^#' | head -5 | while read -r url; do
  echo "    $url"
done
if [[ $COUNT -gt 5 ]]; then
  echo "    ... and $((COUNT - 5)) more"
fi
echo ""
echo "  Next step: ./fetch-transcripts.sh urls.txt"
echo ""
