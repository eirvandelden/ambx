# Building Ambx Lights App with Platypus GUI

If you don't want to use the command-line tool, you can build the app using the Platypus GUI.

## Steps

1. **Open Platypus.app** from Applications or:
   ```bash
   open /opt/homebrew/Caskroom/platypus/5.5.0/Platypus.app
   ```

2. **Configure the app:**

   **Script Path**: Click "Select" and choose:
   ```
   /Users/etienne.vandelden/Developer/conductor/workspaces/ambx/cambridge/applications/menubar/menubar.rb
   ```

   **Interface**: Select **"Status Menu"** from the dropdown

   **Interpreter**: Select **"/usr/bin/ruby"** or type it in

3. **Configure Status Menu:**

   - Click the "Status Menu" tab at the top
   - For **Status Item Icon**, click "Select" and choose:
     ```
     /Users/etienne.vandelden/Developer/conductor/workspaces/ambx/cambridge/applications/menubar/build/icon.png
     ```
   - Leave other settings as default

4. **Add Bundled Files:**

   - Click the "Files" tab
   - Click the "+" button to add files
   - Add the following two items:

     **File 1**: libcombustd library
     ```
     /Users/etienne.vandelden/Developer/conductor/workspaces/ambx/cambridge/libcombustd
     ```

     **File 2**: Colors configuration
     ```
     /Users/etienne.vandelden/Developer/conductor/workspaces/ambx/cambridge/applications/menubar/config/colors.yml
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
   /Users/etienne.vandelden/Developer/conductor/workspaces/ambx/cambridge/applications/menubar/build/Ambx Lights.app
   ```

## Testing

Launch the app:
```bash
open "Ambx Lights.app"
```

The menubar icon should appear in your menu bar. Click it to see the menu with colors and fan speeds.

## Installation

To install permanently:
```bash
cp -r "Ambx Lights.app" /Applications/
```

To launch at startup:
1. Open **System Settings** → **General** → **Login Items**
2. Click **+** and select **Ambx Lights.app**
