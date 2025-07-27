# Git Status Dashboard

[![Release](https://github.com/ejfox/git-status-dash/actions/workflows/production_release.yml/badge.svg)](https://github.com/ejfox/git-status-dash/actions/workflows/production_release.yml)
[![Test Build](https://github.com/ejfox/git-status-dash/actions/workflows/test_build.yml/badge.svg)](https://github.com/ejfox/git-status-dash/actions/workflows/test_build.yml)
[![GitHub release (latest by date)](https://img.shields.io/github/v/release/ejfox/git-status-dash)](https://github.com/ejfox/git-status-dash/releases/latest)
[![npm version](https://img.shields.io/npm/v/git-status-dash)](https://www.npmjs.com/package/git-status-dash)

<img width="1002" alt="Screenshot 2024-06-14 at 1 29 22 AM" src="https://github.com/ejfox/git-status-monitor/assets/530073/67b94585-f78e-4789-986b-25439b8ccce1">

A beautiful, blazingly fast git repository monitor that watches all your repos in real-time. Stop tab-switching to check git status – see everything at once in a gorgeous TUI that adapts to your workflow.

**Why you'll love it:**
- 🚀 **Lightning fast** - Go rewrite is 35% faster with 90% less memory
- 🎨 **Gorgeously themed** - Auto-detects your system theme or import from VS Code/Alacritty  
- ⚙️ **Deeply configurable** - Every detail customizable via intuitive CLI
- 🔍 **Smart monitoring** - Only shows what matters, when it matters

## 🚀 Get the Fastest Version

**Go version is 35% faster, uses 90% less memory, has zero dependencies, and includes advanced theming & config.**

### Quick Start (Recommended)
```bash
# Download the fast Go binary
curl -L https://github.com/ejfox/git-status-dash/releases/latest/download/git-status-dash-go-$(uname -s | tr '[:upper:]' '[:lower:]')-$(uname -m) -o git-status-dash
chmod +x git-status-dash && sudo mv git-status-dash /usr/local/bin/

# Initialize with beautiful defaults
git-status-dash config init
git-status-dash
```

### Or Use Node.js Version
```bash
# Basic usage
npx git-status-dash

# Opens in TUI mode (thanks @zkbkb)
npx git-status-dash -t

# Open another directory
npx git-status-dash -d ~/code/

# Get help
npx git-status-dash --help
```

**Performance comparison on 127 repos:**
- **Go**: 1.159s, 6.7MB RAM ⚡  
- **Node.js**: 1.241s, 69MB RAM

## ⚡ New in Go Version

### 🎨 **Advanced Theming**
- **Auto-detect** system light/dark mode
- **Import themes** from VS Code, Alacritty, Kitty
- **4 built-in themes**: matrix, minimal, hacker, neon
- **Popular themes**: ayu, catppuccin, nord, dracula

### ⚙️ **Deep Configuration**
- **Display**: tree view, timestamps, flash on change
- **Filters**: show/hide by status, recent repos only
- **Behavior**: refresh rates, TTL mode, notifications
- **Performance**: worker pools, timeouts, scan depth

### 🔧 **Quick Config Examples**
```bash
# Set up your perfect environment
git-status-dash config auto                          # Auto-detect theme
git-status-dash config set display.tree_view true    # Tree structure
git-status-dash config set filter.only_recent true   # Recent repos only  
git-status-dash config set behavior.ttl_mode true    # Exit after 30s

# Import themes from other apps
git-status-dash config download ayu-vscode
git-status-dash config import alacritty ~/.config/alacritty/ayu.yml
```

---

## How it works

Recursively scans directories and shows git status for all repos. Defaults to current directory, but you can point it anywhere.

## Development setup

```bash
# Go version
go run *.go

# Node.js version  
npm install && node index.mjs
```
## What's it telling me? 🤔

The table displays the following information for each repository:

- Repository name (relative to the scanned directory)
- Status icon and details:
  - ✓ (green): The repository is in sync with the remote.
  - ↑ (yellow): The local branch is ahead of the remote by the specified number of commits.
  - ↓ (yellow): The local branch is behind the remote by the specified number of commits.
  - ✕ (red): There are uncommitted changes or the repository is not a valid git repo.

The repositories are sorted by the most recently modified ones at the top, so you can quickly see which repos need your attention.


## 🔧 Configuration Reference (Go Version)

### Themes
```bash
git-status-dash config themes                    # List available themes
git-status-dash config theme matrix              # Set theme  
git-status-dash config auto                      # Auto-detect from system
git-status-dash config sources                   # List theme sources
git-status-dash config download ayu-vscode       # Download from source
git-status-dash config import kitty ~/.config/kitty/theme.conf
```

### Display Options
```bash
git-status-dash config set display.tree_view true         # Show as tree
git-status-dash config set display.flash_on_change true   # Flash updates
git-status-dash config set display.show_timestamp true    # Show timestamps
git-status-dash config set display.compact_mode true      # Compact display
git-status-dash config set display.group_by_status true   # Group by status
```

### Filter Options  
```bash
git-status-dash config set filter.show_synced true        # Show clean repos
git-status-dash config set filter.only_recent true        # Recent repos only
git-status-dash config set filter.recent_days 3           # Define "recent"
git-status-dash config set filter.show_dirty false        # Hide dirty repos
```

### Behavior Options
```bash
git-status-dash config set behavior.refresh_interval 500  # Refresh rate (ms)
git-status-dash config set behavior.ttl_mode true         # Exit after timeout
git-status-dash config set behavior.ttl_seconds 30        # Timeout duration
git-status-dash config set behavior.watch_files false     # Disable file watching
git-status-dash config set behavior.notify_on_change true # System notifications
```

### Performance Tuning
```bash
git-status-dash config set performance.workers 8          # Concurrent operations
git-status-dash config set performance.timeout 5          # Git timeout (seconds)
git-status-dash config set performance.max_depth 3        # Scan depth limit
```

### Config File Location
- **Linux/macOS**: `~/.config/git-status-dash/config.json`
- **Windows**: `%APPDATA%/git-status-dash/config.json`
- **Themes**: `~/.config/git-status-dash/themes/`

### Built-in Themes
- **matrix**: Hacker green with effects
- **minimal**: Clean monochrome  
- **hacker**: Retro terminal style
- **neon**: Bright colors and particles

### Supported Theme Sources
- **VS Code**: `.json` theme files
- **Alacritty**: `.yml` config files  
- **Kitty**: `.conf` theme files

---

If you have any questions, suggestions, PRs are welcome. 
