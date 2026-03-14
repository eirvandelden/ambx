#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
VENDOR_DIR="$SCRIPT_DIR/vendor/bundle"

cd "$SCRIPT_DIR"

# Check if Platypus is installed
if ! command -v platypus &> /dev/null; then
    echo "❌ Platypus is not installed"
    echo "Install with: brew install platypus"
    exit 1
fi

# Vendor a standalone bundle so the app does not depend on /usr/bin/ruby gems.
rm -rf "$VENDOR_DIR"
(cd "$REPO_ROOT" && bundle install --standalone --path applications/menubar/build/vendor/bundle)

# Build the Ambx Lights app
platypus \
  --name "Ambx Lights" \
  --interface-type "Status Menu" \
  --interpreter "/usr/bin/ruby" \
  --bundled-file "../../libambx" \
  --bundled-file "./vendor/bundle" \
  --bundled-file "../config/colors.yml" \
  --status-item-icon "icon.png" \
  --quit-after-execution false \
  "../menubar.rb" \
  "./Ambx Lights.app"

echo "✓ Built: build/Ambx Lights.app"
