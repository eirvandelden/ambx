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
    echo "After installation, you may need to install the CLI tool:"
    echo "  Open Platypus.app → Preferences → Install CLI Tool"
    echo "Or run the installer script:"
    echo "  sudo /opt/homebrew/Caskroom/platypus/5.5.0/Platypus.app/Contents/Resources/InstallCommandLineTool.sh /opt/homebrew/Caskroom/platypus/5.5.0/Platypus.app/Contents/Resources"
    exit 1
fi

echo "Using Platypus CLI: $PLATYPUS_CLI"

# Check if Platypus CLI resources are installed system-wide
if [ ! -f "/usr/local/share/platypus/ScriptExec" ] && [[ "$PLATYPUS_CLI" == *"Caskroom"* ]]; then
    echo ""
    echo "⚠️  Platypus CLI resources not installed system-wide"
    echo "Installing CLI tools (requires sudo)..."

    RESOURCES_DIR="$(dirname "$PLATYPUS_CLI")"
    INSTALL_SCRIPT="$RESOURCES_DIR/InstallCommandLineTool.sh"

    if [ -f "$INSTALL_SCRIPT" ]; then
        sudo "$INSTALL_SCRIPT" "$RESOURCES_DIR"
        if [ $? -eq 0 ]; then
            echo "✓ CLI tools installed successfully"
        else
            echo "❌ Failed to install CLI tools"
            echo "Please run manually:"
            echo "  sudo $INSTALL_SCRIPT $RESOURCES_DIR"
            exit 1
        fi
    else
        echo "❌ Install script not found at: $INSTALL_SCRIPT"
        exit 1
    fi
    echo ""
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
