# Ambx Lights - macOS Menubar App

A convenient macOS menubar application for controlling Philips Ambx lights without opening a terminal.

## Features

- 🎨 **Quick Color Selection** - Choose from predefined colors directly from the menubar
- 💨 **Fan Control** - Adjust fan speeds (Off, Low, Medium, High)
- 📡 **Connection Status** - Visual indicator showing if the Ambx device is connected
- ⚙️ **Customizable** - Edit colors and fan speeds in `config/colors.yml`
- 🔆 **LED Compensation** - Automatic green LED brightness boost for color accuracy

## Installation

### Prerequisites

- macOS 10.12+
- Ruby 2.7+ (usually pre-installed)
- Platypus (for building): `brew install platypus`

### Build the App

```bash
cd applications/menubar/build
./build-app.sh
```

This creates `Ambx Lights.app` in the build directory.

### Install

Copy the app to your Applications folder:

```bash
cp -r "applications/menubar/build/Ambx Lights.app" /Applications/
```

Or simply drag `Ambx Lights.app` from Finder to Applications.

### Launch on Startup (Optional)

1. Open **System Settings** → **General** → **Login Items**
2. Click the **+** button and select `Ambx Lights.app` from Applications
3. The app will now launch automatically at startup

## Usage

1. Click the menubar icon to open the menu
2. Select a color or fan speed to apply it
3. The menu shows the connection status:
   - ✓ Connected - Device is ready
   - ⚠️ Disconnected - Device not found (will retry on next action)

## Customization

Edit `config/colors.yml` to customize colors and fan speeds:

```yaml
green_boost: 2.2  # Adjust green LED brightness (1.0 = no boost)

colors:
  - name: "Custom Color"
    rgb: [255, 128, 64]

fan_speeds:
  - name: "Fan: Custom"
    speed: 200  # 0-255
```

After editing, rebuild the app:

```bash
cd applications/menubar/build
./build-app.sh
```

## Architecture

- **menubar.rb** - Main Platypus interface script
- **config/colors.yml** - Color and fan speed definitions
- **build/build-app.sh** - Build automation using Platypus
- **libcombustd/** - USB communication library (bundled in app)

The app uses the existing `libcombustd` library for USB device communication.

## Troubleshooting

### "Platypus is not installed"

Install Platypus:
```bash
brew install platypus
```

### App won't launch

Ensure the USB device is connected and working:
```bash
ruby applications/menubar/menubar.rb
```

Test the script directly:
- Type a color name and press Enter
- Type "Turn Off Lights" to test turning off
- Type "QUIT" to exit

### Colors don't look right

Adjust the `green_boost` value in `config/colors.yml`:
- Increase if green is too dim
- Decrease if green is too bright
- Default: 2.2

## Multiple Devices

The app automatically supports multiple Ambx devices. Each `write` command is sent to all connected devices.

## Testing

### Manual Testing (Command Line)

```bash
cd applications/menubar
ruby menubar.rb
```

- Type color names to test (e.g., "Warm White")
- Type "Turn Off Lights" to test off
- Type "QUIT" to exit

### Interactive Testing

After building and installing:

1. Launch the app from Applications folder
2. Click the menubar icon
3. Select colors and fan speeds
4. Unplug and replug the USB device to test reconnection
5. Check menu updates appropriately

## License

Part of the Ambx Hamburg project
