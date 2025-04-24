# ⚡ TrayScripts

TrayScripts is a lightweight application that creates an icon in the Windows system tray, allowing you to easily run PowerShell scripts and batch files with a click.

## Features

- **System Tray Icon**: Quick access to your scripts through a discreet icon in the system.
- **Dynamic Menu**: Menu contents are dinamically generated from the folder structure in the `scripts` directory and refresh automatically.
- **Multiple Script Support**: Run PowerShell (.ps1) or batch (.bat) scripts from the tray icon.
- **Hierarchical Organization**: Organize your scripts in subfolders for better management.
- **Automatic Startup**: Easy to configure for automatic launch when your computer starts.
- **Autorun Scripts**: Scripts marked with `# autorun = true` will execute automatically when TrayScripts starts.

## System Requirements

- Windows 10 or higher
- PowerShell 5.1 or higher

## Installation

1. Clone or download this repository to your desired location on your computer.
2. Add your PowerShell or batch scripts into the `scripts` folder.
3. (Optional) Add a custom `tray.ico` in the app's main directory.
4. (Optional) Create a shortcut to `TrayScripts.bat` in the Windows startup folder if you want the application to start automatically when your computer turns on.
5. To launch the application, run `TrayScripts.bat`.

### Example: SecondScreen

The application includes an example called "SecondScreen" that shows how to configure scripts:

- `scripts/SecondScreen/On.ps1`: Extends the display to the second screen
- `scripts/SecondScreen/Off.ps1`: Returns to primary display only

### Folder Structure

```
TrayScripts/
├── tray.ps1                # Main script
├── TrayScripts.bat         # Batch launcher
├── tray.ico                # Custom icon (optional)
└── scripts/                # Folder containing your scripts
    ├── YourScript.ps1
    ├── ScriptGroup/
    │   ├── YourScript1.ps1
    │   └── YourScript2.ps1
```

## Creating Custom Scripts

Scripts are simple PowerShell or batch files that execute specific commands. You can create scripts to:

- Automate repetitive tasks
- Manage system configurations
- Control hardware or peripherals
- Launch applications with specific configurations
- Perform any operation you would normally do through PowerShell or command prompt

### Autorun Scripts

You can set up scripts to run automatically when TrayScripts starts by adding this line as the first line of your script:

```powershell
# autorun = true
```

This is useful for:
- Setting up your work environment automatically when you start your computer
- Initializing hardware configurations
- Starting background services or processes you always need

## Security

The application runs scripts with the current user's privileges. Make sure to use only trusted scripts and understand what they do before running them.
