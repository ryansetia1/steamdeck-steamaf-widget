#!/bin/bash
set -e

echo "=== Installing steamAF widget ==="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLASMOID_ID="org.ryan.steamaf"
PLASMOID_DIR="$HOME/.local/share/plasma/plasmoids/$PLASMOID_ID"

rm -rf "$PLASMOID_DIR"
mkdir -p "$(dirname "$PLASMOID_DIR")"
cp -r "$SCRIPT_DIR/plasmoid" "$PLASMOID_DIR"
find "$PLASMOID_DIR" -name __pycache__ -prune -exec rm -rf {} +
echo "[✓] Plasmoid installed to $PLASMOID_DIR"

echo
echo "Restart Plasma to load the new version:"
echo "    systemctl --user restart plasma-plasmashell"
echo
echo "Then: right-click desktop → Add Widgets → \"steamAF\"."
