@echo off
cd /d "%~dp0"
:: ===== Self-elevate to Administrator =====
:: مطلوب لأن الكتابة إلى C:\Program Files تتطلب صلاحيات Admin
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrator privileges...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)
set "PSFILE=%TEMP%\manpower_manual_update.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-Content '%~f0' -Encoding UTF8 | Select-Object -Skip 14 | Set-Content '%PSFILE%' -Encoding UTF8; & '%PSFILE%'"
del "%PSFILE%" >nul 2>&1
exit /b
# ════════════════════════════════════════════════════════════
#  Manpower Manual Update Script - Auto-generated
#  Version: 16.0.15
#  Generated: 2026-10-18 02:49:01
# ════════════════════════════════════════════════════════════

# Disable user input and cursor
[Console]::TreatControlCAsInput = $true
[Console]::CursorVisible = $false
$Host.UI.RawUI.WindowTitle = 'Manpower Manual Update System'

# Ensure console window is fully visible and centered
try {
    Add-Type -Namespace Win32 -Name NativeMethods -MemberDefinition @'
        [System.Runtime.InteropServices.DllImport("kernel32.dll")]
        public static extern System.IntPtr GetConsoleWindow();
        [System.Runtime.InteropServices.DllImport("user32.dll", SetLastError = true)]
        public static extern bool MoveWindow(System.IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);
'@ | Out-Null
    Add-Type -AssemblyName System.Windows.Forms
    $consoleWnd = [Win32.NativeMethods]::GetConsoleWindow()
    if ($consoleWnd -ne [System.IntPtr]::Zero) {
        $wa = [System.Windows.Forms.Screen]::FromHandle($consoleWnd).WorkingArea
        $targetWidth = [Math]::Min(920, [Math]::Max(520, $wa.Width - 120))
        $targetHeight = [Math]::Min(620, [Math]::Max(360, $wa.Height - 140))
        $x = $wa.Left + [Math]::Max(0, [int](($wa.Width - $targetWidth) / 2))
        $y = $wa.Top + [Math]::Max(0, [int](($wa.Height - $targetHeight) / 2))
        [Win32.NativeMethods]::MoveWindow($consoleWnd, $x, $y, $targetWidth, $targetHeight, $true) | Out-Null
        Start-Sleep -Milliseconds 120
        [Win32.NativeMethods]::MoveWindow($consoleWnd, $x, $y, $targetWidth, $targetHeight, $true) | Out-Null
    }
} catch { }

# Color scheme
$COLOR_HEADER = 'Cyan'
$COLOR_INFO = 'White'
$COLOR_PROCESSING = 'Blue'
$COLOR_SUCCESS = 'Green'
$COLOR_WARNING = 'Yellow'
$COLOR_ERROR = 'Red'

# Initialize variables
$COPY_FAILED = 0
$COMPLETED_FILES = 0
$SPINNER = @('|', '/', '-', '\')
$SPINNER_INDEX = 0
$SERVER_PATH = '\\72.60.130.122\Alaq\UpData'
$VERSION_FOLDER = 'repo'
$SOURCE_DIR = Join-Path $SERVER_PATH $VERSION_FOLDER

Clear-Host

# Header
Write-Host ''
Write-Host '========================================' -ForegroundColor $COLOR_HEADER
Write-Host '   Manpower Manual Update System' -ForegroundColor $COLOR_HEADER
Write-Host '   Version: 16.0.15' -ForegroundColor $COLOR_HEADER
Write-Host '========================================' -ForegroundColor $COLOR_HEADER
Write-Host ''
Start-Sleep -Seconds 1

# Step 1: Find Installation
Write-Host '[1/4] ' -NoNewline -ForegroundColor $COLOR_INFO
Write-Host 'Finding Manpower installation...' -ForegroundColor $COLOR_PROCESSING
Write-Host ''

# Try to find from running process
$INSTALL_DIR = $null
$proc = Get-Process -Name 'Manpower' -ErrorAction SilentlyContinue | Select-Object -First 1
if ($proc) {
    $INSTALL_DIR = Split-Path -Parent $proc.Path
    Write-Host '      ' -NoNewline
    Write-Host "Found from running process: $INSTALL_DIR" -ForegroundColor $COLOR_SUCCESS
}

# If not found, search common locations
if (-not $INSTALL_DIR) {
    $searchPaths = @(
        'C:\Program Files\Manpower',
        'C:\Program Files (x86)\Manpower',
        'C:\Manpower',
        'D:\Manpower',
        'E:\Manpower'
    )
    foreach ($p in $searchPaths) {
        if (Test-Path (Join-Path $p 'Manpower.exe')) {
            $INSTALL_DIR = $p
            Write-Host '      ' -NoNewline
            Write-Host "Found at: $INSTALL_DIR" -ForegroundColor $COLOR_SUCCESS
            break
        }
    }
}

# If still not found, ask user
if (-not $INSTALL_DIR) {
    Write-Host '      ' -NoNewline
    Write-Host 'Could not find Manpower automatically.' -ForegroundColor $COLOR_WARNING
    Write-Host ''
    [Console]::CursorVisible = $true
    $INSTALL_DIR = Read-Host '      Enter Manpower installation path'
    [Console]::CursorVisible = $false
    if (-not (Test-Path (Join-Path $INSTALL_DIR 'Manpower.exe'))) {
        Write-Host ''
        Write-Host '========================================' -ForegroundColor $COLOR_ERROR
        Write-Host '   Manpower.exe not found in that path!' -ForegroundColor $COLOR_ERROR
        Write-Host '========================================' -ForegroundColor $COLOR_ERROR
        [Console]::CursorVisible = $true
        Read-Host 'Press Enter to exit'
        exit 1
    }
}

# Verify source folder exists
if (-not (Test-Path $SOURCE_DIR)) {
    Write-Host ''
    Write-Host '========================================' -ForegroundColor $COLOR_ERROR
    Write-Host "   Update folder not found: $VERSION_FOLDER" -ForegroundColor $COLOR_ERROR
    Write-Host '========================================' -ForegroundColor $COLOR_ERROR
    [Console]::CursorVisible = $true
    Read-Host 'Press Enter to exit'
    exit 1
}

# Get list of files to copy
$allFiles = Get-ChildItem -Path $SOURCE_DIR -Recurse -File
$TOTAL_FILES = $allFiles.Count
Write-Host ''
Write-Host '      ' -NoNewline
Write-Host "Installation: $INSTALL_DIR" -ForegroundColor $COLOR_INFO
Write-Host '      ' -NoNewline
Write-Host "Files to update: $TOTAL_FILES" -ForegroundColor $COLOR_INFO
Write-Host ''

# Step 2: Close Application
Write-Host '[2/4] ' -NoNewline -ForegroundColor $COLOR_INFO
Write-Host 'Closing application...' -ForegroundColor $COLOR_PROCESSING
Stop-Process -Name 'Manpower' -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
Write-Host '      ' -NoNewline
Write-Host 'Done' -ForegroundColor $COLOR_SUCCESS
Write-Host ''

# Step 3: Copy Files
Write-Host '[3/4] ' -NoNewline -ForegroundColor $COLOR_INFO
Write-Host "Copying $TOTAL_FILES updated files..." -ForegroundColor $COLOR_PROCESSING
Write-Host ''

# Progress function
function Update-ProgressLine {
    param([string]$FileName, [int]$Current, [int]$Total, [string]$Spin, [bool]$Done = $false)
    $Progress = [math]::Round(($Current * 100) / [math]::Max($Total, 1))
    $Bars = [math]::Floor($Progress / 5)
    $Spaces = 20 - $Bars
    $BarFilled = '#' * $Bars
    $BarEmpty = '-' * $Spaces
    $SavedPos = $Host.UI.RawUI.CursorPosition
    $StatusPos = $SavedPos
    $StatusPos.Y = $Host.UI.RawUI.WindowSize.Height - 3
    $StatusPos.X = 0
    try {
        $Host.UI.RawUI.CursorPosition = $StatusPos
        Write-Host (' ' * 120) -NoNewline
        $Host.UI.RawUI.CursorPosition = $StatusPos
        if ($Done) {
            Write-Host 'Progress: [' -NoNewline -ForegroundColor $COLOR_INFO
            Write-Host $BarFilled -NoNewline -ForegroundColor $COLOR_SUCCESS
            Write-Host $BarEmpty -NoNewline -ForegroundColor DarkGray
            Write-Host '] ' -NoNewline -ForegroundColor $COLOR_INFO
            Write-Host "$Progress%" -NoNewline -ForegroundColor $COLOR_SUCCESS
            Write-Host ' - ' -NoNewline -ForegroundColor $COLOR_INFO
            Write-Host "$Current/$Total files completed" -ForegroundColor $COLOR_SUCCESS
        } else {
            Write-Host 'Progress: [' -NoNewline -ForegroundColor $COLOR_INFO
            Write-Host $BarFilled -NoNewline -ForegroundColor $COLOR_PROCESSING
            Write-Host $BarEmpty -NoNewline -ForegroundColor DarkGray
            Write-Host '] ' -NoNewline -ForegroundColor $COLOR_INFO
            Write-Host "$Progress%" -NoNewline -ForegroundColor $COLOR_PROCESSING
            Write-Host ' - ' -NoNewline -ForegroundColor $COLOR_INFO
            Write-Host "$Spin" -NoNewline -ForegroundColor $COLOR_PROCESSING
            Write-Host ' Copying: ' -NoNewline -ForegroundColor $COLOR_INFO
            Write-Host "$FileName" -ForegroundColor $COLOR_PROCESSING
        }
        if ($SavedPos.Y -ge ($Host.UI.RawUI.WindowSize.Height - 4)) { $SavedPos.Y = $Host.UI.RawUI.WindowSize.Height - 5 }
        $Host.UI.RawUI.CursorPosition = $SavedPos
    } catch { }
}

# Copy each file with retry and spinner
$fileIndex = 0
foreach ($file in $allFiles) {
    $fileIndex++
    $relativePath = $file.FullName.Substring($SOURCE_DIR.Length + 1)
    $fileName = $file.Name
    $destFile = Join-Path $INSTALL_DIR $relativePath
    $destDir = Split-Path -Parent $destFile

    # File header box
    $label = "[$fileIndex/$TOTAL_FILES] $fileName"
    $boxWidth = [math]::Max($label.Length + 4, 41)
    $border = '+' + ('-' * ($boxWidth - 2)) + '+'
    $padded = '| ' + $label.PadRight($boxWidth - 4) + ' |'
    Write-Host $border -ForegroundColor $COLOR_INFO
    Write-Host $padded -ForegroundColor $COLOR_INFO
    Write-Host $border -ForegroundColor $COLOR_INFO

    # Create destination directory
    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Force -Path $destDir | Out-Null
    }

    # Retry logic with spinner
    $retry = 0
    $maxRetries = 3
    $copySuccess = $false
    while (-not $copySuccess -and $retry -lt $maxRetries) {
        for ($j = 0; $j -lt 4; $j++) {
            $spinChar = $SPINNER[$j % 4]
            Update-ProgressLine -FileName $fileName -Current $COMPLETED_FILES -Total $TOTAL_FILES -Spin $spinChar
            Start-Sleep -Milliseconds 250
        }
        try {
            Copy-Item -Path $file.FullName -Destination $destFile -Force -ErrorAction Stop
            $copySuccess = $true
            Write-Host '      ' -NoNewline
            Write-Host 'Copied successfully' -ForegroundColor $COLOR_SUCCESS
            $COMPLETED_FILES++
        } catch {
            $retry++
            if ($retry -lt $maxRetries) {
                Write-Host '      ' -NoNewline
                Write-Host "Attempt $retry/$maxRetries failed: $($_.Exception.Message)" -ForegroundColor $COLOR_WARNING
                Start-Sleep -Seconds 1
            } else {
                Write-Host '      ' -NoNewline
                Write-Host "Failed after $maxRetries attempts: $($_.Exception.Message)" -ForegroundColor $COLOR_ERROR
                $COPY_FAILED = 1
            }
        }
    }
    Update-ProgressLine -FileName $fileName -Current $COMPLETED_FILES -Total $TOTAL_FILES -Spin '' -Done $true
    Start-Sleep -Milliseconds 500
    Write-Host ''
}

# Clear progress line
$ClearPos = $Host.UI.RawUI.CursorPosition
$ClearPos.Y = $Host.UI.RawUI.WindowSize.Height - 3
$ClearPos.X = 0
try { $Host.UI.RawUI.CursorPosition = $ClearPos; Write-Host (' ' * 120) } catch { }
Write-Host ''

# Step 4: Verify
Write-Host '[4/4] ' -NoNewline -ForegroundColor $COLOR_INFO
Write-Host 'Verifying copy completion...' -ForegroundColor $COLOR_PROCESSING
Start-Sleep -Seconds 1
Write-Host '      ' -NoNewline
if ($COPY_FAILED -eq 0) {
    Write-Host 'All files verified' -ForegroundColor $COLOR_SUCCESS
} else {
    Write-Host 'Some files failed!' -ForegroundColor $COLOR_ERROR
}
Write-Host ''

# Completion
if ($COPY_FAILED -eq 0) {
    Write-Host '========================================' -ForegroundColor $COLOR_SUCCESS
    Write-Host '   Update Completed Successfully!' -ForegroundColor $COLOR_SUCCESS
    Write-Host "   ($COMPLETED_FILES/$TOTAL_FILES files copied)" -ForegroundColor $COLOR_INFO
    Write-Host '========================================' -ForegroundColor $COLOR_SUCCESS
    Write-Host ''
    Write-Host 'Starting Manpower...' -ForegroundColor $COLOR_PROCESSING
    $exePath = Join-Path $INSTALL_DIR 'Manpower.exe'
    if (Test-Path $exePath) {
        Start-Process $exePath -WorkingDirectory $INSTALL_DIR
    }
} else {
    Write-Host '========================================' -ForegroundColor $COLOR_ERROR
    Write-Host '   Update Failed!' -ForegroundColor $COLOR_ERROR
    Write-Host "   ($COMPLETED_FILES/$TOTAL_FILES files copied)" -ForegroundColor $COLOR_INFO
    Write-Host '========================================' -ForegroundColor $COLOR_ERROR
}
Write-Host ''

[Console]::CursorVisible = $true
Read-Host 'Press Enter to exit'
