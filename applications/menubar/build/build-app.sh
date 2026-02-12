#!/bin/bash
set -e

cd "$(dirname "$0")"

# Check if Platypus is installed
if ! command -v platypus &> /dev/null; then
    echo "❌ Platypus is not installed"
    echo "Install with: brew install platypus"
    exit 1
fi

# Build the Ambx Lights app
platypus \
  --name "Ambx Lights" \
  --interface-type "Status Menu" \
  --interpreter "/usr/bin/ruby" \
  --bundled-file "../../libcombustd" \
  --bundled-file "../config/colors.yml" \
  --status-item-icon "icon.png" \
  --quit-after-execution false \
  "../menubar.rb" \
  "./Ambx Lights.app"

echo "✓ Built: build/Ambx Lights.app"
