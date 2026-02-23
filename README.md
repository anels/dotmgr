# dotmgr

A PowerShell 7 module for managing dotfiles using a bare Git repo. Track, version, and restore your configuration files without symlinks — files stay in place.

Designed for Windows with OneDrive: place the bare repo in your OneDrive folder for automatic cloud backup and cross-device sync.

## How It Works

`dotmgr` uses a [bare Git repository](https://www.atlassian.com/git/tutorials/dotfiles) pointed at your home directory. This lets you version-control scattered config files (`.gitconfig`, `.claude/`, nvim config, etc.) without moving them or creating symlinks.

```
~/.dotfiles/          # Management directory (this project)
~/OneDrive/.../dotfiles.git   # Bare repo (synced via OneDrive)
~/                    # Work tree (your home directory)
```

## Requirements

- **PowerShell 7+** (pwsh)
- **Git** in PATH

## Installation

```powershell
git clone <repo-url> ~/.dotfiles
~/.dotfiles/install.ps1
```

The installer:
1. Symlinks the module into your `PSModulePath`
2. Adds a `dot` alias to your PowerShell profile
3. Verifies the module loads correctly

Then initialize:

```powershell
dot init
```

The interactive wizard will guide you through choosing a repo location and selecting config files to track.

## Usage

```
dot init                  Interactive setup wizard
dot add <path>            Stage files/folders for tracking
dot remove <path>         Untrack files (keeps on disk)
dot list                  List all tracked files
dot status                Show pending changes
dot diff [path]           Show file differences
dot commit [message]      Commit staged changes
dot restore [path]        Restore files to last commit
dot log [n]               View commit history (default: 20)
dot show <path> [ref]     Show committed version of a file
dot doctor                Health check
dot help                  Show help message
```

Short aliases: `st` (status), `ci` (commit), `ls` (list), `rm` (remove), `cat` (show).

### Examples

```powershell
# Track a config file
dot add ~/.gitconfig

# Track an entire folder (new files auto-tracked on future commits)
dot add ~/.claude

# Check what changed
dot status
dot diff

# Commit changes
dot commit "update powershell aliases"

# Restore a file to the last committed version
dot restore ~/.claude/CLAUDE.md

# View history
dot log
```

## Safety

- Sensitive files (`*.pem`, `*.key`, `*.env`, `*secret*`, etc.) are blocked by default. Use `-Force` to override.
- Large files (>1MB) prompt for confirmation.
- `dot restore` without arguments requires `[y/N]` confirmation.
- `dot remove` only untracks files — it never deletes them from disk.

## Project Structure

```
DotfilesManager/
├── DotfilesManager.psd1        # Module manifest
├── DotfilesManager.psm1        # Module loader
├── Public/
│   └── Invoke-Dot.ps1          # Entry point + command router + tab completion
├── Commands/                   # Subcommand implementations
│   ├── Invoke-DotInit.ps1
│   ├── Invoke-DotAdd.ps1
│   ├── Invoke-DotRemove.ps1
│   ├── Invoke-DotStatus.ps1
│   ├── Invoke-DotDiff.ps1
│   ├── Invoke-DotCommit.ps1
│   ├── Invoke-DotRestore.ps1
│   ├── Invoke-DotLog.ps1
│   ├── Invoke-DotList.ps1
│   ├── Invoke-DotDoctor.ps1
│   └── Invoke-DotHelp.ps1
└── Private/                    # Internal helpers
    ├── Git.ps1                 # Bare git operations
    ├── Config.ps1              # config.json read/write
    ├── Security.ps1            # Sensitive file blocking
    └── Format.ps1              # Output formatting
```

## License

MIT
