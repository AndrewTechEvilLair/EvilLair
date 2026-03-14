#!/bin/bash
# ============================================================
# add-page.sh — Evil Lair Homepage Injector
# Usage: ./add-page.sh "Page Name" "filename.html" "🔥" "Short description of the project."
# ============================================================

set -e

PAGE_NAME="$1"
FILE_NAME="$2"
ICON="$3"
DESC="$4"

# --- Validate args ---
if [ -z "$PAGE_NAME" ] || [ -z "$FILE_NAME" ] || [ -z "$ICON" ] || [ -z "$DESC" ]; then
  echo ""
  echo "  Usage: ./add-page.sh \"Page Name\" \"filename.html\" \"🔥\" \"Short description.\""
  echo ""
  echo "  Example:"
  echo "    ./add-page.sh \"Commute Finder\" \"commute-finder.html\" \"🗺️\" \"Find homes by commute time.\""
  echo ""
  exit 1
fi

INDEX="index.html"
MARKER="<!-- ADD_PAGE_HERE -->"

# --- Check index.html exists ---
if [ ! -f "$INDEX" ]; then
  echo "❌  $INDEX not found. Run this from your repo root."
  exit 1
fi

# --- Check marker exists ---
if ! grep -q "$MARKER" "$INDEX"; then
  echo ""
  echo "⚠️  Marker comment not found in $INDEX."
  echo "    Add this line inside your .projects-grid div where you want new cards to appear:"
  echo ""
  echo "    $MARKER"
  echo ""
  exit 1
fi

# --- Count existing project cards to set animation delay ---
CARD_COUNT=$(grep -c 'class="project-card"' "$INDEX" || true)
NEXT_CHILD=$((CARD_COUNT + 1))
DELAY=$(echo "scale=1; $NEXT_CHILD * 0.1 + 0.2" | bc)

# --- Build the new card HTML ---
NEW_CARD=$(cat <<CARD

    <a href="https://andrewtechevillair.github.io/${FILE_NAME%.*}/" class="project-card" style="animation-delay: ${DELAY}s;">
      <span class="project-icon">${ICON}</span>
      <div class="project-name">${PAGE_NAME^^}</div>
      <p class="project-desc">${DESC}</p>
      <span class="project-link-label">LAUNCH →</span>
    </a>

    ${MARKER}
CARD
)

# --- Inject card before marker ---
# Use perl for reliable multiline replacement (works on both Mac and Linux)
perl -i -0pe "s|${MARKER}|${NEW_CARD}|" "$INDEX"

echo ""
echo "✅  Added \"${PAGE_NAME}\" card to $INDEX"
echo "    → Points to: https://andrewtechevillair.github.io/${FILE_NAME%.*}/"
echo "    → Icon: ${ICON}"
echo "    → Animation delay: ${DELAY}s (card #${NEXT_CHILD})"
echo ""

# --- Git commit (no auto-push — you review first) ---
read -p "📦  Stage and commit now? (y/n): " CONFIRM
if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
  git add "$INDEX"
  git commit -m "feat: add ${PAGE_NAME} to homepage"
  echo ""
  echo "✅  Committed. Run 'git push' when you're ready."
  echo ""
else
  echo ""
  echo "👍  Skipped commit. Changes are saved to $INDEX — review and push when ready."
  echo ""
fi
