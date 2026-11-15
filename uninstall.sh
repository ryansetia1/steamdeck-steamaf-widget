#!/bin/bash
set -e

echo "=== Uninstalling steamAF widget ==="
rm -rf "$HOME/.local/share/plasma/plasmoids/org.ryan.steamaf"
echo "[✓] Removed. Remove the widget from your desktop and restart Plasma:"
echo "    systemctl --user restart plasma-plasmashell"
