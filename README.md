# FFWall - Folder Level Firewall

A PowerShell-based tool for creating session-managed Windows Firewall rules to block executables at the folder level. FFWall recursively scans directories, avoids junctions and symlinks, and provides granular control over firewall rule management.

## Features

- **Recursive Scanning**: Automatically discovers all executable files in a directory tree
- **Junction/Symlink Safety**: Intelligently avoids traversing into junctions, directory symlinks, and file symlinks
- **Session-Based Management**: Organize firewall rules into named sessions for easy management
- **Duplicate Prevention**: Detects existing firewall rules and skips creation to prevent duplicates  
- **Comprehensive Logging**: Detailed logs for scan, block, and rollback operations with timestamps
- **Auto-Elevation**: Automatically requests administrator privileges when needed via UAC
- **Clean Interface**: Black console background with color-coded status messages and admin indicator
- **Safe Rollback**: Session-specific rule removal that won't affect other firewall rules

## Requirements

- Windows PowerShell 5.1 or PowerShell Core 7+
- Windows 10/11 or Windows Server 2016+
- Administrator privileges (for blocking and rollback operations)

## Installation

1. Download `FFWall.ps1` to your desired location
2. Right-click the file and select "Run with PowerShell"
3. If prompted about execution policy, choose "Yes" or run: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

## Usage

### Basic Workflow

1. **Scan**: Create a session by scanning a directory for executable files
2. **Block**: Apply firewall rules to block network access for discovered executables
3. **Rollback**: Remove all firewall rules associated with a specific session

### Menu Interface

```
============================
FFWall - FolderLevel Firewall [ADMIN]
============================
1. Scan and list all .exe files
2. Block all scanned .exe files  
3. Rollback FFWall rules
4. Exit
============================
Current Session Tag: mysession
```

The interface shows admin status in the title bar and tracks your current session.

### Scanning

The scan operation:
- Recursively searches for `.exe` files in the current directory
- Automatically avoids junctions, symlinks, and reparse points
- Creates a session log file: `scan_[sessionname].log`
- Shows real-time progress with file discovery and skip notifications

Example output:
```
[1] Found: application.exe
[2] Found: subfolder\tool.exe
[SKIP] File Symlink: linkedapp.exe
[SKIP] Directory Junction/Symlink: external.exe (in junction_folder)
```

### Blocking

The block operation:
- Lists available sessions with file counts for easy selection
- Creates Windows Firewall rules for both inbound and outbound traffic
- Uses consistent naming: `FFWall_[session]_[IN/OUT]_[filename]`
- Checks for existing rules to prevent duplicates
- Provides detailed progress and error reporting
- Creates a block log file: `block_[sessionname].log`

Example output:
```
Available session files:
  test1 (5 files)
  test2 (3 files)
  mysession (3 files)

[1/3] Processing: application.exe
  [SUCCESS] Created outbound rule for application.exe
  [SUCCESS] Created inbound rule for application.exe
[2/3] Processing: tool.exe  
  [SKIP] Outbound rule already exists for tool.exe
  [SUCCESS] Created inbound rule for tool.exe
```

### Rollback

The rollback operation:
- Lists available sessions with active rule counts
- Shows preview of rules to be removed with session selection interface
- Uses wildcard deletion for efficient cleanup
- Only removes FFWall-created rules (safe operation)
- Creates a rollback log file: `rollback_[sessionname].log`

Example output:
```
Available sessions:
  test1 (5 files, 10 active rules)
  test2 (3 files, no active rules)  
  mysession (3 files, 6 active rules)
```

## File Structure

FFWall creates several types of log files in the working directory:

- `scan_[session].log` - Contains discovered executable paths and scan metadata
- `block_[session].log` - Contains firewall rule creation results and errors  
- `rollback_[session].log` - Contains firewall rule removal results and metadata

## Safety Features

### Junction and Symlink Avoidance
- Detects reparse points at both file and directory levels
- Prevents infinite loops and access to unintended locations
- Uses PowerShell's native attribute checking for reliable detection

### Firewall Rule Isolation
- All rules use distinctive naming convention: `FFWall_[session]_[direction]_[filename]`
- Session-based management prevents accidental deletion of other rules
- Wildcard operations are limited to FFWall-created rules only

### Administrator Privilege Management
- Automatically detects privilege level and shows status in title bar
- Requests elevation via standard Windows UAC when needed
- Graceful fallback for operations that don't require admin rights

## Advanced Usage

### Running from Command Line
```powershell
# Navigate to directory to scan
cd "C:\MyApplications"

# Run FFWall
.\FFWall.ps1
```

### Batch Processing Multiple Directories
For scanning multiple directories, run FFWall from each target directory individually. Each location will create its own session logs and firewall rules.

## Troubleshooting

### Execution Policy Errors
If you receive execution policy errors, run:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Permission Errors
- Ensure you're running as Administrator for blocking and rollback operations
- FFWall will automatically request elevation when needed via UAC popup

### Firewall Rule Conflicts
- Use the scan operation to verify which executables will be affected
- Check existing firewall rules in Windows Firewall with Advanced Security
- Use session-specific rollbacks to remove only intended rules

## Technical Details

### Firewall Rule Creation
- Uses PowerShell's `New-NetFirewallRule` cmdlet for reliable rule creation
- Creates separate inbound and outbound rules for comprehensive blocking
- Implements duplicate detection and comprehensive error handling

### Symlink Detection Algorithm  
- Checks file-level reparse points using `FileAttributes.ReparsePoint`
- Traverses directory hierarchy checking each parent for reparse points
- Uses PowerShell's native `Get-Item` with force and error handling

### User Interface
- Black console background for improved readability
- Color-coded status messages (Green=success, Red=error, Yellow=warning, Cyan=info)
- Admin status indicator in title bar
- Session management with easy selection interfaces

## Contributing

Contributions are welcome! Please ensure any pull requests:
- Maintain backward compatibility with existing session logs
- Include appropriate error handling and logging
- Follow the established naming conventions for firewall rules
- Test against various Windows versions and PowerShell editions

## License

This project is released under the GNU General Public License v3.0. This ensures that:
- The software remains free and open source
- Any derivative works must also be open source
- Proper attribution is maintained for all contributors
- Commercial use is permitted but source code must remain available

See LICENSE file for full details.

## Credits

**Original Concept and Development**  
SR21 - Core architecture design, safety requirements, session management system, initial batch prototype and comprehensive testing

**Initial Implementation**  
ChatGPT (OpenAI) - Foundational batch file structure, firewall command scaffolding, and basic menu system

**PowerShell Conversion and Advanced Features**  
Claude (Anthropic) - Complete PowerShell rewrite, robust error handling, symlink/junction detection, UAC integration, logging system, and user interface improvements

This project represents collaborative development between human creativity and AI assistance across multiple iterations.

## Version History

- **v2.0** - Complete PowerShell rewrite with enhanced safety features, improved user experience, duplicate prevention, and session selection interfaces
- **v1.0** - Initial batch file implementation with basic functionality

---

**Warning**: This tool creates Windows Firewall rules that block network access for applications. Always test in a controlled environment before deploying to critical systems. Use rollback functionality to remove rules when no longer needed.
