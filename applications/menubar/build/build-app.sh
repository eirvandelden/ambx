#!/bin/bash
set -e

cd "$(dirname "$0")"

# Find Platypus CLI tool
PLATYPUS_CLI=""

# Check for Homebrew Cask installation (most common on Apple Silicon)
if [ -f "/opt/homebrew/Caskroom/platypus/5.5.0/Platypus.app/Contents/Resources/platypus_clt" ]; then
    PLATYPUS_CLI="/opt/homebrew/Caskroom/platypus/5.5.0/Platypus.app/Contents/Resources/platypus_clt"
# Check for Homebrew Cask installation (Intel Macs)
elif [ -f "/usr/local/Caskroom/platypus/5.5.0/Platypus.app/Contents/Resources/platypus_clt" ]; then
    PLATYPUS_CLI="/usr/local/Caskroom/platypus/5.5.0/Platypus.app/Contents/Resources/platypus_clt"
# Check if installed system-wide
elif command -v platypus &> /dev/null; then
    PLATYPUS_CLI="platypus"
else
    echo "❌ Platypus is not installed or CLI tool not found"
    echo "Install with: brew install platypus"
    echo ""
    echo "After installation, install the CLI tool:"
    echo "  Open Platypus.app → Preferences → Install CLI Tool"
    exit 1
fi

echo "Using Platypus CLI: $PLATYPUS_CLI"

# Allow test overrides for the CLI path and resources check path
if [ -n "$PLATYPUS_CLI_OVERRIDE" ]; then
    PLATYPUS_CLI="$PLATYPUS_CLI_OVERRIDE"
fi
PLATYPUS_RESOURCES_CHECK="${PLATYPUS_RESOURCES_CHECK:-/usr/local/share/platypus/ScriptExec}"

# Check if Platypus CLI resources are installed system-wide
if [ ! -f "$PLATYPUS_RESOURCES_CHECK" ] && [[ "$PLATYPUS_CLI" == *"Caskroom"* ]]; then
    RESOURCES_DIR="$(dirname "$PLATYPUS_CLI")"
    INSTALL_SCRIPT="$RESOURCES_DIR/InstallCommandLineTool.sh"
    echo ""
    echo "❌ Platypus CLI resources not installed system-wide."
    echo "Run the following command to install them, then re-run this script:"
    echo ""
    echo "  sudo \"$INSTALL_SCRIPT\" \"$RESOURCES_DIR\""
    echo ""
    exit 1
fi

# Detect Ruby interpreter (use current ruby with gem dependencies)
RUBY_INTERPRETER="$(which ruby)"
echo "Using Ruby interpreter: $RUBY_INTERPRETER"

# Build the Ambx Lights app
"$PLATYPUS_CLI" \
  --name "Ambx Lights" \
  --interface-type "Status Menu" \
  --interpreter "$RUBY_INTERPRETER" \
  --bundled-file "../../../libcombustd" \
  --bundled-file "../config/colors.yml" \
  --status-item-icon "icon.png" \
  "../menubar.rb" \
  "./Ambx Lights.app"

echo "✓ Built: build/Ambx Lights.app"
