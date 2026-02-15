#!/bin/bash
# Comic Tracker Cover Downloader
# Downloads REAL comic book covers from bol.com
set -e

COVERS_DIR="/home/louis/.openclaw/workspace/comic-tracker/public/covers"
HTML_FILE="/home/louis/.openclaw/workspace/comic-tracker/public/index.html"
mkdir -p "$COVERS_DIR"

# Only downloading Suske en Wiske — other series need manual covers
declare -A series_slugs=(
  ["Suske en Wiske"]="suske-en-wiske"
)

echo "📦 Comic Tracker — Real Cover Downloader"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Extract all series/volume/title combos from the HTML, find missing covers
missing=()
while IFS='|' read -r series vol title; do
  slug="${series_slugs[$series]}"
  [ -z "$slug" ] && continue
  fname="${slug}-${vol}.jpg"
  [ -f "$COVERS_DIR/$fname" ] && continue
  missing+=("$series|$vol|$title|$fname")
done < <(python3 -c "
import re, json

with open('$HTML_FILE') as f:
    html = f.read()

# Extract the SERIES object from JavaScript
m = re.search(r'const SERIES = (\{.+?\});', html, re.DOTALL)
if not m:
    exit(1)

# Clean JS object to valid JSON
js = m.group(1)
# Fix: {n:1,t:\"title\"} -> {\"n\":1,\"t\":\"title\"}
js = re.sub(r'(\{)\s*n:', r'\1\"n\":', js)
js = re.sub(r',\s*t:', r',\"t\":', js)
# Fix unquoted keys
js = re.sub(r'\"([^\"]+)\":\s*\[', r'\"\\1\": [', js)

series = json.loads(js)
for name, albums in series.items():
    for a in albums:
        print(f\"{name}|{a['n']}|{a['t']}\")
")

total=${#missing[@]}
echo "Missing covers: $total"
echo ""

if [ "$total" -eq 0 ]; then
  echo "✅ All covers present!"
  exit 0
fi

# Pick 5 random missing covers
selected=$(printf '%s\n' "${missing[@]}" | shuf | head -5)

downloaded=0
failed=0

echo "$selected" | while IFS='|' read -r series vol title fname; do
  [ -z "$series" ] && continue
  
  echo "🔍 $series #$vol — $title"
  
  # Search bol.com for the cover
  search=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$series $vol $title strip'))")
  
  cover_url=$(curl -s -L "https://www.bol.com/nl/nl/s/?searchtext=${search}" \
    -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
    -H "Accept: text/html,application/xhtml+xml" \
    -H "Accept-Language: nl-NL,nl;q=0.9" \
    2>/dev/null | grep -oP 'https://media\.s-bol\.com/[^"]+\.jpg' | head -1)
  
  if [ -z "$cover_url" ]; then
    echo "  ✗ No cover image found"
    failed=$((failed + 1))
    continue
  fi
  
  # Download
  http_code=$(curl -s -o "$COVERS_DIR/$fname" -w "%{http_code}" -L "$cover_url" \
    -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36" 2>/dev/null)
  
  if [ "$http_code" != "200" ]; then
    rm -f "$COVERS_DIR/$fname"
    echo "  ✗ Download failed (HTTP $http_code)"
    failed=$((failed + 1))
    continue
  fi
  
  # Validate: must be >5KB (real covers are 50-200KB)
  filesize=$(stat -c%s "$COVERS_DIR/$fname" 2>/dev/null || echo "0")
  if [ "$filesize" -lt 5000 ]; then
    rm -f "$COVERS_DIR/$fname"
    echo "  ✗ Image too small (${filesize}B), likely not a real cover"
    failed=$((failed + 1))
    continue
  fi
  
  echo "  ✓ Downloaded: $fname ($(( filesize / 1024 ))KB)"
  downloaded=$((downloaded + 1))
  
  # Be polite — wait between requests
  sleep 2
done

echo ""
echo "✅ Done! Downloaded: $downloaded, Failed: $failed"
echo "   Remaining missing: $((total - downloaded))"
