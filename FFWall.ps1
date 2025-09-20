<#
╔════════════════════════════════════════════════════════════════════════════╗
║														        			 ║
║             ________  ________  __       __            __  __              ║
║            |        \|        \|  \  _  |  \          |  \|  \             ║
║            | $$$$$$$$| $$$$$$$$| $$ / \ | $$  ______  | $$| $$             ║
║            | $$__    | $$__    | $$/  $\| $$ |      \ | $$| $$             ║
║            | $$  \   | $$  \   | $$  $$$\ $$  \$$$$$$\| $$| $$             ║
║            | $$$$$   | $$$$$   | $$ $$\$$\$$ /      $$| $$| $$             ║
║            | $$      | $$      | $$$$  \$$$$|  $$$$$$$| $$| $$             ║
║            | $$      | $$      | $$$    \$$$ \$$    $$| $$| $$             ║
║             \$$       \$$       \$$      \$$  \$$$$$$$ \$$ \$$             ║
║                                                   					     ║            
║                                                     					     ║
║                             Folder Level Firewall              	         ║
║                                  Version 2.0                          	 ║
╚════════════════════════════════════════════════════════════════════════════╝

FFWall - A PowerShell-based tool for creating session-managed Windows 
Firewall rules to block executables at the folder level. It recursively 
scans directories, avoids junctions and symlinks, and provides granular 
control over firewall rule management.

FEATURES:
- Recursive scanning with junction/symlink safety
- Session-based firewall rule management  
- Duplicate rule prevention
- Auto-elevation with UAC integration
- Comprehensive logging and audit trails
- Safe rollback operations

╔════════════════════════════════════════════════════════════════════════════╗																		
║															  			     ║
║           LICENSE: GPL v3 - This software is free and open source. 	     ║
║          Any derivative works must also be open source and properly		 ║ 
║                   attributed to the original creators.                     ║
║                                                                            ║
╚════════════════════════════════════════════════════════════════════════════╝

CREDITS & DEVELOPMENT HISTORY:
┌────────────────────────────────────────────────────────────────────────────┐
│                                                                            │
│   Original Concept & Architecture:                                         │
│     • Sairamkumar M [SR21] - Core design, safety requirements, session     │
│       management architecture, initial batch prototype and comprehensive   │
│       testing.                                                             │
│                                                                            │
│   Initial Implementation:                                                  │
│     • ChatGPT (OpenAI) - Foundational batch file structure, firewall       │
│       command scaffolding, and basic menu system                           │
│                                                                            │
│   PowerShell Conversion & Advanced Features:                               │
│     • Claude (Anthropic) - Complete rewrite to PowerShell, robust error    │
│       handling, symlink/junction detection, UAC integration, logging       │
│       system, and user interface improvements                              │
│                                                                            │
│   Collaborative Development:                                               │
│     • This project represents the combined efforts of human creativity,    │
│       AI assistance, and iterative problem-solving across multiple         │
│       development cycles                                                   │
│                                                                            │
└────────────────────────────────────────────────────────────────────────────┘

REPOSITORY: https://github.com/sairamkumarm/ffwall
DOCUMENTATION: See README.md for detailed usage instructions

╔════════════════════════════════════════════════════════════════════════════╗
║																      	     ║																					
║  WARNING: This tool creates Windows Firewall rules that block network      ║
║  access for applications. Always test in a controlled environment before   ║
║  deploying to critical systems. Use rollback functionality to  			 ║
║  remove rules when no longer needed.									     ║
║                                                                            ║
╠════════════════════════════════════════════════════════════════════════════╣
║                                                                            ║
║  Copyright (C) 2025 FFWall Contributors                                    ║
║  This program is free software: you can redistribute it and/or modify it   ║
║  under the terms of the GNU General Public License as published by the     ║
║  Free Software Foundation, either version 3 of the License, or             ║
║  (at your option) any later version.                                       ║
║                                                                            ║
║  This program is distributed in the hope that it will be useful, but       ║
║  WITHOUT ANY WARRANTY; without even the implied warranty of                ║
║  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                      ║
║  See the GNU General Public License for more details.                      ║
║  You should have received a copy of the GNU General Public License along   ║
║  with this program. If not, see <https://www.gnu.org/licenses/>.           ║
║                                                                            ║
╚════════════════════════════════════════════════════════════════════════════╝
#>

# Set console colors for the script session
$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "White"
Clear-Host

# Check if running as Administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Request administrator privileges if not already running as admin
function Request-AdminPrivileges {
    if (-not (Test-Administrator)) {
        Write-Host "Requesting administrator privileges..." -ForegroundColor Yellow
        
        # Get the current script path more reliably
        $scriptPath = $PSCommandPath
        if ([string]::IsNullOrEmpty($scriptPath)) {
            $scriptPath = $MyInvocation.MyCommand.Source
        }
        if ([string]::IsNullOrEmpty($scriptPath)) {
            $scriptPath = $MyInvocation.MyCommand.Path
        }
        
        if ([string]::IsNullOrEmpty($scriptPath)) {
            Write-Host "Could not determine script path. Please run as Administrator manually." -ForegroundColor Red
            Read-Host "Press Enter to continue in non-admin mode"
            return
        }
        
        try {
            # Create a command that will run the script and keep window open
            $command = "Set-Location '$PWD'; & '$scriptPath'"
            
            # Start a new PowerShell process as Administrator
            Start-Process -FilePath "powershell.exe" -ArgumentList "-NoExit", "-Command", $command -Verb RunAs
            # Exit current non-admin process
            exit
        }
        catch {
            Write-Host "Failed to elevate privileges. Please run as Administrator manually." -ForegroundColor Red
            Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
            Read-Host "Press Enter to continue in non-admin mode"
        }
    }
}

# Check admin privileges at startup
if (-not (Test-Administrator)) {
    Write-Host "FFWall requires Administrator privileges for blocking and rollback operations." -ForegroundColor Yellow
    $elevate = Read-Host "Would you like to restart as Administrator? (Y/N)"
    if ($elevate -match "^[Yy]$") {
        Request-AdminPrivileges
    } else {
        Write-Host "Continuing in non-admin mode. Scanning will work, but blocking/rollback will fail." -ForegroundColor Yellow
        Write-Host ""
    }
}

# Set execution policy for current session if needed
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force -ErrorAction SilentlyContinue

# Initialize variables
$global:SessionTag = ""
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

function Show-Menu {
    Clear-Host
    $adminStatus = if (Test-Administrator) { " [ADMIN]" } else { " [USER]" }
    $adminColor = if (Test-Administrator) { "Green" } else { "Yellow" }
    
    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host "FFWall - FolderLevel Firewall" -ForegroundColor Cyan -NoNewline
    Write-Host $adminStatus -ForegroundColor $adminColor
    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host "1. Scan and list all .exe files" -ForegroundColor White
    Write-Host "2. Block all scanned .exe files" -ForegroundColor White
    Write-Host "3. Rollback FFWall rules" -ForegroundColor White
    Write-Host "4. Exit" -ForegroundColor White
    Write-Host "=====================================" -ForegroundColor Cyan
    
    if ($global:SessionTag -ne "") {
        Write-Host "Current Session Tag: $global:SessionTag" -ForegroundColor Yellow
    }
    Write-Host ""
}

function Get-TimeStamp {
    return Get-Date -Format "yyyy-MM-dd HH:mm:ss"
}

function Start-ScanPhase {
    Clear-Host
    Write-Host "============================" -ForegroundColor Green
    Write-Host "        SCAN PHASE" -ForegroundColor Green
    Write-Host "============================" -ForegroundColor Green
    
    # Ask for session name
    $ScanSession = Read-Host "Enter a session name for this scan (no spaces)"
    if ([string]::IsNullOrWhiteSpace($ScanSession)) {
        Write-Host "Session name cannot be empty." -ForegroundColor Red
        Read-Host "Press Enter to continue"
        return
    }
    
    $ScanLogFile = Join-Path $ScriptPath "scan_$ScanSession.log"
    
    # Check if file already exists
    if (Test-Path $ScanLogFile) {
        Write-Host ""
        Write-Host "WARNING: Session file already exists: $ScanLogFile" -ForegroundColor Yellow
        Write-Host "This will overwrite the existing scan data." -ForegroundColor Yellow
        $overwrite = Read-Host "Do you want to overwrite the existing scan? (Y/N)"
        if ($overwrite -notmatch "^[Yy]$") {
            Write-Host "Scan cancelled." -ForegroundColor Red
            Read-Host "Press Enter to continue"
            return
        }
    }
    
    Write-Host ""
    Write-Host "Scanning for .exe files in: $ScriptPath" -ForegroundColor Cyan
    Write-Host "Session: $ScanSession" -ForegroundColor Cyan
    Write-Host "Output file: $ScanLogFile" -ForegroundColor Cyan
    Write-Host ""
    $confirm = Read-Host "Proceed with scan? (Y/N)"
    if ($confirm -notmatch "^[Yy]$") {
        Write-Host "Scan cancelled." -ForegroundColor Red
        Read-Host "Press Enter to continue"
        return
    }
    
    Write-Host ""
    Write-Host "Scanning recursively, avoiding junctions and symlinks..." -ForegroundColor Yellow
    
    # Get timestamp
    $timestamp = Get-TimeStamp
    
    # Create log header
    $logHeader = @"
============================
      FFWALL SCAN LOG
============================
Operation: SCAN
Date/Time: $timestamp
Session: $ScanSession
Scan Path: $ScriptPath
============================

"@
    
    $logHeader | Out-File -FilePath $ScanLogFile -Encoding UTF8
    
    # Perform scan with proper junction/symlink detection
    $fileCount = 0
    $validFiles = @()
    
    Write-Host ""
    Write-Host "Starting scan..." -ForegroundColor Yellow
    
    try {
        # Get all .exe files, including those in junctions/symlinks (so we can explicitly skip them)
        $allExeFiles = Get-ChildItem -Path $ScriptPath -Filter "*.exe" -Recurse -Force -FollowSymlink -ErrorAction SilentlyContinue
        
        foreach ($file in $allExeFiles) {
            $skipFile = $false
            
            # First check if the file itself is a symlink
            if ($file.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
                $skipFile = $true
                Write-Host "[SKIP] File Symlink: $($file.Name)" -ForegroundColor Red
            }
            
            # If not a file symlink, check if any parent directory is a reparse point
            if (-not $skipFile) {
                $currentPath = $file.DirectoryName
                while ($currentPath -and $currentPath.Length -gt $ScriptPath.Length) {
                    $dirInfo = Get-Item -Path $currentPath -Force -ErrorAction SilentlyContinue
                    if ($dirInfo -and ($dirInfo.Attributes -band [System.IO.FileAttributes]::ReparsePoint)) {
                        $skipFile = $true
                        Write-Host "[SKIP] Directory Junction/Symlink: $($file.Name) (in $($dirInfo.Name))" -ForegroundColor Red
                        break
                    }
                    $currentPath = Split-Path -Parent $currentPath
                }
            }
            
            if (-not $skipFile) {
                $fileCount++
                Write-Host "[$fileCount] Found: $($file.Name)" -ForegroundColor Green
                $validFiles += $file.FullName
                $file.FullName | Add-Content -Path $ScanLogFile -Encoding UTF8
            }
        }
    }
    catch {
        Write-Host "Error during scan: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Add footer to log
    $logFooter = @"

============================
        SCAN SUMMARY
============================
Total .exe files found: $fileCount
Status: SUCCESS
============================
"@
    
    $logFooter | Add-Content -Path $ScanLogFile -Encoding UTF8
    
    Write-Host ""
    Write-Host "============================" -ForegroundColor Green
    Write-Host "       SCAN COMPLETE" -ForegroundColor Green
    Write-Host "============================" -ForegroundColor Green
    Write-Host "Session: $ScanSession" -ForegroundColor Cyan
    Write-Host "Total .exe files found: $fileCount" -ForegroundColor Cyan
    Write-Host "Saved to: $ScanLogFile" -ForegroundColor Cyan
    Write-Host ""
    
    if ($fileCount -gt 0) {
        Write-Host "Files found:" -ForegroundColor White
        foreach ($file in $validFiles) {
            Write-Host "  $file" -ForegroundColor Gray
        }
    } else {
        Write-Host "No .exe files found in this directory tree." -ForegroundColor Yellow
    }
    
    # Set current session
    $global:SessionTag = $ScanSession
    
    Write-Host ""
    Read-Host "Press Enter to continue"
}

function Get-FileCountFromLog($logPath) {
    if (-not (Test-Path $logPath)) { return 0 }
    
    $content = Get-Content $logPath -Encoding UTF8
    $fileCount = 0
    
    foreach ($line in $content) {
        if ($line -match "^[A-Za-z]:\\" -and $line -notmatch "====|Operation:|Date/Time:|Session:|Scan Path:|Total .exe files found:|Status:") {
            $fileCount++
        }
    }
    
    return $fileCount
}

function Start-BlockPhase {
    Clear-Host
    Write-Host "============================" -ForegroundColor Red
    Write-Host "        BLOCK PHASE" -ForegroundColor Red
    Write-Host "============================" -ForegroundColor Red
    
    # Check for administrator privileges
    if (-not (Test-Administrator)) {
        Write-Host ""
        Write-Host "Administrator privileges required for blocking!" -ForegroundColor Red
        $elevate = Read-Host "Restart as Administrator? (Y/N)"
        if ($elevate -match "^[Yy]$") {
            Request-AdminPrivileges
        } else {
            Write-Host "Cannot proceed without administrator privileges." -ForegroundColor Red
            Read-Host "Press Enter to continue"
        }
        return
    }
    
    # Look for existing scan files
    Write-Host "Looking for existing scan files..." -ForegroundColor Yellow
    $scanFiles = Get-ChildItem -Path $ScriptPath -Filter "scan_*.log" -ErrorAction SilentlyContinue
    
    if ($scanFiles.Count -eq 0) {
        Write-Host "No scan files found. Please run a scan first." -ForegroundColor Red
        Read-Host "Press Enter to continue"
        return
    }
    
    Write-Host ""
    Write-Host "Available session files:" -ForegroundColor White
    foreach ($file in $scanFiles) {
        $sessionName = $file.BaseName.Substring(5)  # Remove "scan_" prefix
        $fileCount = Get-FileCountFromLog $file.FullName
        Write-Host "  $sessionName ($fileCount files)" -ForegroundColor Gray
    }
    
    Write-Host ""
    $blockSession = ""
    
    if ($global:SessionTag -ne "") {
        Write-Host "Current session: $global:SessionTag" -ForegroundColor Yellow
        $useCurrent = Read-Host "Use current session '$global:SessionTag' for blocking? (Y/N)"
        if ($useCurrent -match "^[Yy]$") {
            $blockSession = $global:SessionTag
        }
    }
    
    if ($blockSession -eq "") {
        $blockSession = Read-Host "Enter session name to block"
        if ([string]::IsNullOrWhiteSpace($blockSession)) {
            Write-Host "Session name cannot be empty." -ForegroundColor Red
            Read-Host "Press Enter to continue"
            return
        }
    }
    
    $scanLogFile = Join-Path $ScriptPath "scan_$blockSession.log"
    $blockLogFile = Join-Path $ScriptPath "block_$blockSession.log"
    
    if (-not (Test-Path $scanLogFile)) {
        Write-Host "Scan file not found: $scanLogFile" -ForegroundColor Red
        Read-Host "Press Enter to continue"
        return
    }
    
    # Count files from scan log
    $totalExe = Get-FileCountFromLog $scanLogFile
    
    if ($totalExe -eq 0) {
        Write-Host "No executables found in scan file." -ForegroundColor Red
        Read-Host "Press Enter to continue"
        return
    }
    
    # Get file list from scan log
    $content = Get-Content $scanLogFile -Encoding UTF8
    $exeFiles = @()
    
    foreach ($line in $content) {
        if ($line -match "^[A-Za-z]:\\" -and $line -notmatch "====|Operation:|Date/Time:|Session:|Scan Path:|Total .exe files found:|Status:") {
            $exeFiles += $line.Trim()
        }
    }
    
    Write-Host ""
    Write-Host "============================" -ForegroundColor Red
    Write-Host "      BLOCKING PREVIEW" -ForegroundColor Red
    Write-Host "============================" -ForegroundColor Red
    Write-Host "Session: $blockSession" -ForegroundColor Cyan
    Write-Host "Files to block: $totalExe" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "The following executables will be blocked:" -ForegroundColor White
    foreach ($file in $exeFiles) {
        Write-Host "  $file" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "This will create $($totalExe * 2) firewall rules ($totalExe inbound + $totalExe outbound)." -ForegroundColor Yellow
    $confirm = Read-Host "CONFIRM: Block all these executables? (Y/N)"
    if ($confirm -notmatch "^[Yy]$") {
        Write-Host "Blocking cancelled." -ForegroundColor Red
        Read-Host "Press Enter to continue"
        return
    }
    
    # Get timestamp for log
    $timestamp = Get-TimeStamp
    
    # Initialize block log
    $logHeader = @"
============================
     FFWALL BLOCK LOG
============================
Operation: BLOCK
Date/Time: $timestamp
Session: $blockSession
Target Files: $totalExe
============================

"@
    
    $logHeader | Out-File -FilePath $blockLogFile -Encoding UTF8
    
    Write-Host ""
    Write-Host "============================" -ForegroundColor Red
    Write-Host "         BLOCKING..." -ForegroundColor Red
    Write-Host "============================" -ForegroundColor Red
    
    # Initialize counters
    $count = 0
    $errorCount = 0
    $successCount = 0
    
    foreach ($file in $exeFiles) {
        $count++
        $fileName = Split-Path -Leaf $file
        Write-Host "[$count/$totalExe] Processing: $fileName" -ForegroundColor Yellow
        
        $rulesCreated = 0
        
        # Try to create outbound rule
        $outRuleName = "FFWall_${blockSession}_OUT_$fileName"
        $existingOutRule = Get-NetFirewallRule -DisplayName $outRuleName -ErrorAction SilentlyContinue
        
        if ($existingOutRule) {
            Write-Host "  [SKIP] Outbound rule already exists for $fileName" -ForegroundColor Cyan
            "SKIP (OUT): $file - Rule already exists" | Add-Content -Path $blockLogFile -Encoding UTF8
        } else {
            try {
                $null = New-NetFirewallRule -DisplayName $outRuleName -Direction Outbound -Program $file -Action Block -ErrorAction Stop
                Write-Host "  [SUCCESS] Created outbound rule for $fileName" -ForegroundColor Green
                "SUCCESS (OUT): $file" | Add-Content -Path $blockLogFile -Encoding UTF8
                $rulesCreated++
            }
            catch {
                $errorCount++
                Write-Host "  [ERROR] Failed to create outbound rule for $fileName" -ForegroundColor Red
                "ERROR (OUT): $file - $($_.Exception.Message)" | Add-Content -Path $blockLogFile -Encoding UTF8
            }
        }
        
        # Try to create inbound rule
        $inRuleName = "FFWall_${blockSession}_IN_$fileName"
        $existingInRule = Get-NetFirewallRule -DisplayName $inRuleName -ErrorAction SilentlyContinue
        
        if ($existingInRule) {
            Write-Host "  [SKIP] Inbound rule already exists for $fileName" -ForegroundColor Cyan
            "SKIP (IN): $file - Rule already exists" | Add-Content -Path $blockLogFile -Encoding UTF8
        } else {
            try {
                $null = New-NetFirewallRule -DisplayName $inRuleName -Direction Inbound -Program $file -Action Block -ErrorAction Stop
                Write-Host "  [SUCCESS] Created inbound rule for $fileName" -ForegroundColor Green
                "SUCCESS (IN): $file" | Add-Content -Path $blockLogFile -Encoding UTF8
                $rulesCreated++
            }
            catch {
                $errorCount++
                Write-Host "  [ERROR] Failed to create inbound rule for $fileName" -ForegroundColor Red
                "ERROR (IN): $file - $($_.Exception.Message)" | Add-Content -Path $blockLogFile -Encoding UTF8
            }
        }
        
        if ($rulesCreated -eq 0) {
            Write-Host "  No new rules created (all already existed)" -ForegroundColor Gray
        }
    }
    
    # Calculate success count
    $expectedRules = $totalExe * 2
    $successCount = $expectedRules - $errorCount
    
    # Add footer to block log
    $status = if ($errorCount -eq 0) { "SUCCESS" } else { "PARTIAL SUCCESS" }
    $logFooter = @"

============================
      BLOCKING SUMMARY
============================
Total files processed: $totalExe
Expected rules: $expectedRules
Successful rules: $successCount
Failed rules: $errorCount
Status: $status
============================
"@
    
    $logFooter | Add-Content -Path $blockLogFile -Encoding UTF8
    
    # Update current session
    $global:SessionTag = $blockSession
    
    Write-Host ""
    Write-Host "============================" -ForegroundColor Red
    Write-Host "     BLOCKING COMPLETE" -ForegroundColor Red
    Write-Host "============================" -ForegroundColor Red
    Write-Host "Session: $blockSession" -ForegroundColor Cyan
    Write-Host "Files processed: $totalExe" -ForegroundColor Cyan
    Write-Host "Successful rules: $successCount/$expectedRules" -ForegroundColor Green
    Write-Host "Failed rules: $errorCount" -ForegroundColor Red
    
    if ($errorCount -gt 0) {
        Write-Host "WARNING: Some rules failed - check block_$blockSession.log for details" -ForegroundColor Yellow
    }
    
    Write-Host "Log saved to: $blockLogFile" -ForegroundColor Cyan
    Write-Host ""
    Read-Host "Press Enter to continue"
}

function Start-RollbackPhase {
    Clear-Host
    Write-Host "============================" -ForegroundColor Magenta
    Write-Host "      ROLLBACK PHASE" -ForegroundColor Magenta
    Write-Host "============================" -ForegroundColor Magenta
    
    # Check for administrator privileges
    if (-not (Test-Administrator)) {
        Write-Host ""
        Write-Host "Administrator privileges required for rollback!" -ForegroundColor Red
        $elevate = Read-Host "Restart as Administrator? (Y/N)"
        if ($elevate -match "^[Yy]$") {
            Request-AdminPrivileges
        } else {
            Write-Host "Cannot proceed without administrator privileges." -ForegroundColor Red
            Read-Host "Press Enter to continue"
        }
        return
    }

    # Look for existing scan files to show available sessions
    Write-Host "Looking for available sessions..." -ForegroundColor Yellow
    $scanFiles = Get-ChildItem -Path $ScriptPath -Filter "scan_*.log" -ErrorAction SilentlyContinue
    
    if ($scanFiles.Count -gt 0) {
        Write-Host ""
        Write-Host "Available sessions:" -ForegroundColor White
        foreach ($file in $scanFiles) {
            $sessionName = $file.BaseName.Substring(5)  # Remove "scan_" prefix
            $fileCount = Get-FileCountFromLog $file.FullName
            
            # Check if there are any firewall rules for this session
            $existingRules = Get-NetFirewallRule -DisplayName "FFWall_$sessionName*" -ErrorAction SilentlyContinue
            $ruleCount = if ($existingRules) { $existingRules.Count } else { 0 }
            
            if ($ruleCount -gt 0) {
                Write-Host "  $sessionName ($fileCount files, $ruleCount active rules)" -ForegroundColor Green
            } else {
                Write-Host "  $sessionName ($fileCount files, no active rules)" -ForegroundColor Gray
            }
        }
    }
    
    $rollbackSession = ""
    
    if ($global:SessionTag -ne "") {
        Write-Host ""
        Write-Host "Current session: $global:SessionTag" -ForegroundColor Yellow
        $useCurrent = Read-Host "Use current session '$global:SessionTag' for rollback? (Y/N)"
        if ($useCurrent -match "^[Yy]$") {
            $rollbackSession = $global:SessionTag
        }
    }
    
    if ($rollbackSession -eq "") {
        Write-Host ""
        $rollbackSession = Read-Host "Enter session name to rollback"
        if ([string]::IsNullOrWhiteSpace($rollbackSession)) {
            Write-Host "Session name cannot be empty." -ForegroundColor Red
            Read-Host "Press Enter to continue"
            return
        }
    }
    
    Write-Host ""
    Write-Host "Searching for firewall rules with session tag '$rollbackSession'..." -ForegroundColor Yellow
    
    # Check if any rules exist
    $existingRules = Get-NetFirewallRule -DisplayName "FFWall_$rollbackSession*" -ErrorAction SilentlyContinue
    
    if ($existingRules.Count -eq 0) {
        Write-Host "No firewall rules found for session: $rollbackSession" -ForegroundColor Red
        Read-Host "Press Enter to continue"
        return
    }
    
    Write-Host ""
    Write-Host "============================" -ForegroundColor Magenta
    Write-Host "      ROLLBACK PREVIEW" -ForegroundColor Magenta
    Write-Host "============================" -ForegroundColor Magenta
    Write-Host "Session: $rollbackSession" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Found the following firewall rules:" -ForegroundColor White
    foreach ($rule in $existingRules) {
        Write-Host "  $($rule.DisplayName)" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "This will remove ALL $($existingRules.Count) firewall rules for session: $rollbackSession" -ForegroundColor Yellow
    $confirm = Read-Host "CONFIRM: Remove all these firewall rules? (Y/N)"
    if ($confirm -notmatch "^[Yy]$") {
        Write-Host "Rollback cancelled." -ForegroundColor Red
        Read-Host "Press Enter to continue"
        return
    }
    
    # Get timestamp for log
    $timestamp = Get-TimeStamp
    $rollbackLogFile = Join-Path $ScriptPath "rollback_$rollbackSession.log"
    
    # Initialize rollback log
    $logHeader = @"
============================
    FFWALL ROLLBACK LOG
============================
Operation: ROLLBACK
Date/Time: $timestamp
Session: $rollbackSession
============================

Rules found before rollback:
"@
    
    $logHeader | Out-File -FilePath $rollbackLogFile -Encoding UTF8
    
    foreach ($rule in $existingRules) {
        "Rule Name: $($rule.DisplayName)" | Add-Content -Path $rollbackLogFile -Encoding UTF8
    }
    
    "" | Add-Content -Path $rollbackLogFile -Encoding UTF8
    
    Write-Host ""
    Write-Host "============================" -ForegroundColor Magenta
    Write-Host "      ROLLING BACK..." -ForegroundColor Magenta
    Write-Host "============================" -ForegroundColor Magenta
    
    # Remove all rules with the session tag
    Write-Host "Removing all rules for session: $rollbackSession" -ForegroundColor Yellow
    $rollbackStatus = "SUCCESS"
    
    try {
        Remove-NetFirewallRule -DisplayName "FFWall_$rollbackSession*" -ErrorAction Stop
        Write-Host "SUCCESS: All rules removed successfully" -ForegroundColor Green
        "Rollback command: Remove-NetFirewallRule -DisplayName `"FFWall_$rollbackSession*`"" | Add-Content -Path $rollbackLogFile -Encoding UTF8
        "Status: SUCCESS" | Add-Content -Path $rollbackLogFile -Encoding UTF8
    }
    catch {
        $rollbackStatus = "FAILED"
        Write-Host "ERROR: Failed to remove rules for session: $rollbackSession" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        "Rollback command: Remove-NetFirewallRule -DisplayName `"FFWall_$rollbackSession*`"" | Add-Content -Path $rollbackLogFile -Encoding UTF8
        "Status: FAILED" | Add-Content -Path $rollbackLogFile -Encoding UTF8
        "Error: $($_.Exception.Message)" | Add-Content -Path $rollbackLogFile -Encoding UTF8
    }
    
    # Add footer to rollback log
    $logFooter = @"

============================
     ROLLBACK SUMMARY
============================
Session: $rollbackSession
Status: $rollbackStatus
============================
"@
    
    $logFooter | Add-Content -Path $rollbackLogFile -Encoding UTF8
    
    # Clear current session if it matches what we just rolled back
    if ($global:SessionTag -eq $rollbackSession) {
        $global:SessionTag = ""
    }
    
    Write-Host ""
    Write-Host "============================" -ForegroundColor Magenta
    Write-Host "     ROLLBACK COMPLETE" -ForegroundColor Magenta
    Write-Host "============================" -ForegroundColor Magenta
    Write-Host "Session: $rollbackSession" -ForegroundColor Cyan
    Write-Host "Status: $rollbackStatus" -ForegroundColor $(if ($rollbackStatus -eq "SUCCESS") { "Green" } else { "Red" })
    Write-Host "Log saved to: $rollbackLogFile" -ForegroundColor Cyan
    Write-Host ""
    Read-Host "Press Enter to continue"
}

# Main execution loop
while ($true) {
    Show-Menu
    $choice = Read-Host "Select an option (1-4)"
    
    switch ($choice) {
        "1" { Start-ScanPhase }
        "2" { Start-BlockPhase }
        "3" { Start-RollbackPhase }
        "4" { 
            Clear-Host
            Write-Host ""
            Write-Host "===============================" -ForegroundColor Cyan
            Write-Host "           GOODBYE!" -ForegroundColor Cyan
            Write-Host "===============================" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "       Happy Blocking!" -ForegroundColor Green
            Write-Host ""
            Write-Host "       Compliments of:" -ForegroundColor White
            Write-Host "    SR21, Claude & ChatGPT" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "===============================" -ForegroundColor Cyan
            Write-Host ""
            exit 
        }
        default { 
            Write-Host "Invalid option. Please select 1-4." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }

}
