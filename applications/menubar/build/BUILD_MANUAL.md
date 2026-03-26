# Building Ambx Lights App with Platypus GUI

If you don't want to use the command-line tool, you can build the app using the Platypus GUI.

## Prerequisites

- Platypus installed: `brew install platypus`
- All commands below assume you are in the root of the repository checkout.

## Steps

1. **Open Platypus.app** from Applications or Spotlight.

2. **Configure the app:**

   **Script Path**: Click "Select" and navigate to:
   ```
   applications/menubar/menubar.rb
   ```

   **Interface**: Select **"Status Menu"** from the dropdown

   **Interpreter**: Click "Select" and choose the Ruby interpreter used by the project.
   To find the right path, run:
   ```bash
   which ruby
   ```

3. **Configure Status Menu:**

   - Click the "Status Menu" tab at the top
   - For **Status Item Icon**, click "Select" and choose:
     ```
     applications/menubar/build/icon.png
     ```
   - Leave other settings as default

4. **Add Bundled Files:**

   - Click the "Files" tab
   - Click the "+" button to add files
   - Add the following three items:

     **File 1**: libcombustd library
     ```
     libcombustd
     ```

     **File 2**: Menubar helpers
     ```
     applications/menubar/menubar_helpers.rb
     ```

     **File 3**: Colors configuration
     ```
     applications/menubar/config/colors.yml
     ```

5. **Configure App Settings:**

   - Click the "Settings" tab
   - **App Name**: `Ambx Lights`
   - Leave **"Runs in background"** unchecked
   - Leave **"Quit after execution"** unchecked

6. **Create the App:**

   - Click **"Create App"** button at the bottom
   - Choose save location: `applications/menubar/build/`
   - Name it: `Ambx Lights.app`
   - Click **"Create"**

7. **Done!** Your app is now ready at:
   ```
   applications/menubar/build/Ambx Lights.app
   ```

## Testing

Launch the app:
```bash
open "applications/menubar/build/Ambx Lights.app"
```

The menubar icon should appear in your menu bar. Click it to see the menu with colors and fan speeds.

## Installation

To install permanently:
```bash
cp -r "applications/menubar/build/Ambx Lights.app" /Applications/
```

To launch at startup:
1. Open **System Settings** → **General** → **Login Items**
2. Click **+** and select **Ambx Lights.app**
