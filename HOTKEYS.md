# Keyboard Shortcuts Guide

**Niri with Omarchy-Inspired Keybindings + Midnight Ember Theme**

These keybindings are adapted from [Omarchy](https://learn.omacom.io/2/the-omarchy-manual/53/hotkeys) (DHH's Linux setup) for the Niri compositor.

---

## Quick Reference

| Action | Shortcut |
|--------|----------|
| App Launcher (Fuzzel) | `Super + Space` |
| Terminal (Kitty) | `Super + Return` |
| Close Window | `Super + W` |
| Fullscreen | `Super + F` |
| Toggle Floating | `Super + O` |
| Toggle Vibe/Focus Mode | `Super + Shift + V` |
| Night Mode Toggle | `Super + Ctrl + N` |
| Quit Niri | `Super + Escape` |

---

## Navigation

### Window Focus

| Action | Shortcut |
|--------|----------|
| Focus left | `Super + ←` or `Super + H` |
| Focus down | `Super + ↓` or `Super + J` |
| Focus up | `Super + ↑` or `Super + K` |
| Focus right | `Super + →` or `Super + L` |

### Move Windows

| Action | Shortcut |
|--------|----------|
| Move left | `Super + Shift + ←` or `Super + Shift + H` |
| Move down | `Super + Shift + ↓` or `Super + Shift + J` |
| Move up | `Super + Shift + ↑` or `Super + Shift + K` |
| Move right | `Super + Shift + →` or `Super + Shift + L` |

### Workspaces

| Action | Shortcut |
|--------|----------|
| Go to workspace 1-9 | `Super + 1-9` |
| Next workspace | `Super + Tab` |
| Previous workspace | `Super + Shift + Tab` |
| Move window to workspace 1-9 | `Super + Shift + 1-9` |
| Scroll workspaces | `Super + Mouse Wheel` |
| Move window + scroll | `Super + Shift + Mouse Wheel` |

### Window Management

| Action | Shortcut |
|--------|----------|
| Close window | `Super + W` |
| Fullscreen | `Super + F` |
| Toggle floating | `Super + O` |
| Maximize width | `Super + Alt + F` |
| Grow width | `Super + =` |
| Shrink width | `Super + -` |
| Grow height | `Super + Shift + =` |
| Shrink height | `Super + Shift + -` |

### Column Grouping

| Action | Shortcut |
|--------|----------|
| Group window into column | `Super + G` |
| Ungroup window | `Super + Alt + G` |
| Toggle grouping | `Super + T` |

---

## Launching Apps

### GUI Apps

| App | Shortcut |
|-----|----------|
| App Launcher (Fuzzel) | `Super + Space` |
| Terminal (Kitty) | `Super + Return` |
| Browser (Firefox) | `Super + Shift + B` |
| File Manager (Thunar) | `Super + Shift + F` |
| Music (Spotify) | `Super + Shift + M` |
| Code Editor (VSCode) | `Super + Shift + N` |
| Notes (Obsidian) | `Super + Shift + O` |
| Password Manager (Bitwarden) | `Super + Shift + /` |

### TUI Apps (Terminal-based)

| App | Shortcut |
|-----|----------|
| Yazi (File Manager) | `Super + E` |
| Lazygit | `Super + Shift + D` |
| Lazydocker | `Super + Ctrl + D` |
| ncspot (Spotify TUI) | `Super + Shift + P` |
| Cava (Audio Visualizer) | `Super + Shift + C` |
| btop (System Monitor) | `Super + Ctrl + T` |

---

## System Controls

| Action | Shortcut |
|--------|----------|
| Audio settings | `Super + Ctrl + A` |
| Bluetooth settings | `Super + Ctrl + B` |
| WiFi settings | `Super + Ctrl + W` |
| Lock screen | `Super + Ctrl + L` |
| Night mode toggle | `Super + Ctrl + N` |
| Reload Niri config | `Super + Ctrl + R` |
| Quit Niri | `Super + Escape` |

---

## Mode Toggle (Midnight Ember)

| Mode | Description | Toggle |
|------|-------------|--------|
| **Vibe Mode** | Gaps: 12px, smooth animations, transparency | `Super + Shift + V` |
| **Focus Mode** | Gaps: 0px, instant animations, opaque | `Super + Shift + V` |

---

## Screenshots & Recording

| Action | Shortcut |
|--------|----------|
| Screenshot to clipboard (select area) | `Super + Shift + S` |
| Screenshot (select area, save + clipboard) | `Print Screen` |
| Screenshot (full screen) | `Super + Print Screen` |
| Screen record toggle | `screenrecord` (CLI) |
| Screen record region | `screenrecord region` (CLI) |

---

## Clipboard

| Action | Shortcut |
|--------|----------|
| Clipboard history | `Super + Ctrl + V` |

*Note: cliphist runs automatically at startup*

---

## Media Keys

| Action | Key |
|--------|-----|
| Volume up | `Volume Up` |
| Volume down | `Volume Down` |
| Mute | `Mute` |
| Mute mic | `Mic Mute` |
| Play/Pause | `Play` |
| Next track | `Next` |
| Previous track | `Previous` |

---

## Custom Scripts

| Script | Usage |
|--------|-------|
| `night-mode` | `night-mode [on\|off\|toggle\|status]` - Blue light filter |
| `screenrecord` | `screenrecord [start\|stop\|region\|toggle\|status]` - NVENC recording |
| `toggle-mode` | Switches between Vibe and Focus mode |
| `webapp-install` | `webapp-install <name> <url> [icon-url]` - Create web app |
| `webapp-remove` | `webapp-remove [name]` - Remove web app |
| `webapp-list` | List installed web apps |

---

## Workspace Assignments

Apps auto-open on specific workspaces:

| Workspace | Apps |
|-----------|------|
| 1 | Firefox, Chromium |
| 2 | Google Messages, WhatsApp, Cliq, RingCentral |
| 3 | VS Code, Kitty, Alacritty, Obsidian |

---

## Fish Shell Aliases

| Alias | Command |
|-------|---------|
| `nrs` | `sudo nixos-rebuild switch` |
| `nrt` | `sudo nixos-rebuild test` |
| `g` | `git` |
| `cat` | `bat` |
| `ls` | `eza` |
| `cd` | `z` (zoxide) |

---

## Customization

Edit the Niri config to customize keybindings:

```bash
# Edit config
nano ~/.config/niri/config.kdl

# Validate syntax
niri validate ~/.config/niri/config.kdl

# Reload config
niri msg action load-config-file
# Or use: Super + Ctrl + R
```

---

## Midnight Ember Color Palette

| Color | Hex | Usage |
|-------|-----|-------|
| Background | `#0d1117` | Base dark |
| Surface | `#161b22` | Bars, panels |
| Border | `#30363d` | Subtle borders |
| Text | `#e6edf3` | Primary text |
| Accent (Orange) | `#f97316` | Active, highlights |
| Accent (Cyan) | `#22d3ee` | Info, secondary |
| Success | `#22c55e` | Green |
| Warning | `#eab308` | Yellow |
| Error | `#ef4444` | Red |

---

## Sources

- [Omarchy Hotkeys Manual](https://learn.omacom.io/2/the-omarchy-manual/53/hotkeys)
- [Omarchy Cheat Sheet](https://acrogenesis.com/omarchy-cheat-sheet/)
- [Niri Wiki](https://github.com/YaLTeR/niri/wiki)
- [vyrx-dev/dotfiles](https://github.com/vyrx-dev/dotfiles) (Dual mode inspiration)

---

*Config location: `~/.config/niri/config.kdl`*
*Theme: Midnight Ember*
*Last updated: 2026-01-18*
