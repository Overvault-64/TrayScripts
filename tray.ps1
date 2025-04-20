# tray.ps1
# TrayScripts - System tray application for running scripts
# 
# Hint: You can add "# autorun = true" at the beginning of your scripts
# to make them automatically execute when TrayScripts starts.

$appName = "TrayScripts"
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Single instance check
$MUTEX_ID = $appName + "Mutex-GUID-Here"
$mutex = New-Object System.Threading.Mutex($false, $MUTEX_ID)

# Standardize dialog messages
$dialogTitle = $appName

if (-not $mutex.WaitOne(0, $false)) {
    [System.Windows.Forms.MessageBox]::Show(
        $appName + " is already running",
        $dialogTitle,
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
    exit
}

# Get script directory
$scriptDir = $PSScriptRoot
$scriptsRoot = Join-Path $scriptDir "scripts" # Base scripts directory
$iconPath = Join-Path $scriptDir "tray.ico"

# Create tray icon
$tray_icon = New-Object System.Windows.Forms.NotifyIcon
$tray_icon.Text = $appName

# Load custom icon or fallback
if (Test-Path $iconPath) {
    try {
        $tray_icon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($iconPath)
    } catch {
        Write-Warning "Failed to load custom icon '$iconPath'. Using default Application icon. Error: $($_.Exception.Message)"
        $tray_icon.Icon = [System.Drawing.SystemIcons]::Application
    }
}
else {
    Write-Warning "Custom icon '$iconPath' not found. Using default Application icon."
    $tray_icon.Icon = [System.Drawing.SystemIcons]::Application
}

# Create context menu
$menu = New-Object System.Windows.Forms.ContextMenuStrip

# Function to execute scripts
function Invoke-Script {
    param (
        [string]$FilePath,
        [string]$WorkingDir
    )
    
    try {
        if ($FilePath.EndsWith('.ps1')) {
            $pwsh = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
            $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$FilePath`""
            
            [System.Diagnostics.Process]::Start($pwsh, $arguments) | Out-Null
        }
        elseif ($FilePath.EndsWith('.bat')) {
            [System.Diagnostics.Process]::Start("cmd.exe", "/c `"$FilePath`"") | Out-Null
        }
    }
    catch {
        $errorMsg = $_.Exception.Message
        
        [System.Windows.Forms.MessageBox]::Show(
            "Failed to execute script '$FilePath'.`nError: $errorMsg",
            $dialogTitle,
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
}

# Function to check for autorun scripts and execute them
function Invoke-AutorunScripts {
    param (
        [string]$DirectoryPath
    )

    if (-not (Test-Path $DirectoryPath -PathType Container)) {
        Write-Warning "Directory '$DirectoryPath' not found. Skipping autorun check."
        return
    }

    # Get all PowerShell scripts in the directory and subdirectories
    $scriptFiles = Get-ChildItem -Path $DirectoryPath -Filter "*.ps1" -Recurse -File
    
    foreach ($scriptFile in $scriptFiles) {
        # Read first line of the script to check for autorun directive
        $scriptContent = Get-Content -Path $scriptFile.FullName -TotalCount 1 -ErrorAction SilentlyContinue
        
        if ($scriptContent -match '^\s*#\s*autorun\s*=\s*true\s*$') {
            Write-Host "Executing autorun script: $($scriptFile.FullName)"
            Invoke-Script -FilePath $scriptFile.FullName -WorkingDir $scriptFile.DirectoryName
        }
    }
}

# Generic handler for menu item clicks
function OnMenuItemClick {
    param($menuSender, $e)
    
    # Get the menuItem that triggered the event
    $menuItem = $menuSender
    
    # Verify it's a valid menuitem with Tag
    if ($null -ne $menuItem -and $null -ne $menuItem.Tag) {
        $scriptInfo = $menuItem.Tag
        
        # Execute the script using the helper function
        Invoke-Script -FilePath $scriptInfo.FilePath -WorkingDir $scriptInfo.WorkingDir
    }
    else {
        $errorMsg = "Unable to find script information to execute"
        
        [System.Windows.Forms.MessageBox]::Show(
            $errorMsg,
            $dialogTitle,
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
}

# --- Function to dynamically generate menu ---
function Add-MenuItemsFromDirectory {
    param(
        [Parameter(Mandatory=$true)]
        [string]$DirectoryPath,

        [Parameter(Mandatory=$true)]
        [System.Object]$ParentCollection
    )

    # Verify that the passed object is a valid collection
    if ($null -eq $ParentCollection -or -not ($ParentCollection.PSObject.Methods.Name -contains 'Add')) {
         Write-Error "ParentCollection must be a collection with an 'Add' method. Object received: $($ParentCollection.GetType().FullName)"
         return
    }

    # Get items in the current directory
    $items = Get-ChildItem -Path $DirectoryPath -ErrorAction SilentlyContinue

    if ($null -eq $items) {
        Write-Warning "Cannot access or find items in '$DirectoryPath'"
        return
    }

    # Add submenus for each subfolder
    foreach ($dir in $items | Where-Object { $_.PSIsContainer }) {
        $subMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem($dir.Name)
        $ParentCollection.Add($subMenuItem) | Out-Null
        # Recursive call for subfolders
        Add-MenuItemsFromDirectory -DirectoryPath $dir.FullName -ParentCollection $subMenuItem.DropDownItems
    }

    # Add menu items for each script (.ps1, .bat)
    foreach ($file in $items | Where-Object { !$_.PSIsContainer -and ($_.Extension -eq '.ps1' -or $_.Extension -eq '.bat') }) {
        $menuItemName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        $scriptItem = New-Object System.Windows.Forms.ToolStripMenuItem($menuItemName)
        
        # Use Tag to store necessary data
        $scriptItem.Tag = @{
            FilePath = $file.FullName
            WorkingDir = $file.DirectoryName
        }
        
        # Connect the event handler using Add_Click with the function defined above
        $scriptItem.Add_Click({ OnMenuItemClick $this $_ })
        
        $ParentCollection.Add($scriptItem) | Out-Null
    }
}

# Function to refresh the menu content
function Update-MenuItems {
    # Clear current menu items, except exit item
    # Save the exit item
    $exitItem = $null
    foreach ($item in $menu.Items) {
        if ($item.Text -eq "Exit") {
            $exitItem = $item
            break
        }
    }
    
    # Clear all menu items
    $menu.Items.Clear()
    
    # Populate with fresh content
    if (Test-Path $scriptsRoot -PathType Container) {
        Add-MenuItemsFromDirectory -DirectoryPath $scriptsRoot -ParentCollection $menu.Items
    } else {
        Write-Warning "Scripts directory '$scriptsRoot' not found. No script menus will be generated."
        # Add a placeholder item if the folder doesn't exist
        $noScriptsItem = $menu.Items.Add("Scripts folder not found")
        $noScriptsItem.Enabled = $false
    }
    
    # Add separator and exit item back
    if ($menu.Items.Count -gt 0) {
        $menu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator)) | Out-Null
    }
    
    # Add the exit item (either the original or a new one if it didn't exist)
    if ($null -ne $exitItem) {
        $menu.Items.Add($exitItem) | Out-Null
    } else {
        $exitItem = $menu.Items.Add("Exit")
        $exitItem.Add_Click({
            $tray_icon.Visible = $false
            $mutex.ReleaseMutex()
            [System.Windows.Forms.Application]::Exit()
        })
    }
}

# Event handler for menu opening
$menu.Add_Opening({
    # Update menu items on opening
    Update-MenuItems
})

# Initial menu setup
Update-MenuItems

# Execute autorun scripts
Invoke-AutorunScripts -DirectoryPath $scriptsRoot

# Final setup
$tray_icon.ContextMenuStrip = $menu
$tray_icon.Visible = $true

# Hide main window
$null = (Add-Type -MemberDefinition @'
[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
'@ -Name Win32 -Namespace Functions -PassThru)::ShowWindow(
    (Get-Process -PID $pid).MainWindowHandle,
    0 # 0 = SW_HIDE
)

# Start application
[System.Windows.Forms.Application]::Run()

# Cleanup
$tray_icon.Dispose()
$mutex.Dispose()