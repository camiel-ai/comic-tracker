#!/bin/bash
# Deploy comic-tracker to ai-wolf.nl
set -e

LOCAL="/home/louis/.openclaw/workspace/comic-tracker"
REMOTE="aiwolf:/home/aiwolf/domains/comic-tracker.ai-wolf.nl"

echo "📦 Syncing app files..."
scp "$LOCAL/server.js" "$LOCAL/package.json" "$LOCAL/package-lock.json" "$REMOTE/"

echo "📄 Syncing HTML to public dir (served by Express)..."
scp "$LOCAL/public/index.html" "$LOCAL/public/lijst.html" "$REMOTE/public_html/public/" 2>/dev/null

echo "🖼️  Syncing covers..."
rsync -avz --progress "$LOCAL/public/covers/" "$REMOTE/public_html/covers/"

echo "🔄 Restarting app..."
ssh aiwolf "source /home/aiwolf/nodevenv/domains/comic-tracker.ai-wolf.nl/18/bin/activate && cd /home/aiwolf/domains/comic-tracker.ai-wolf.nl && npm install --production 2>&1 && touch tmp/restart.txt"

echo "✅ Deployed!"
