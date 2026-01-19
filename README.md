# Dotfiles - Midnight Ember

My NixOS + Niri configuration with "Midnight Ember" theme.

## Setup

- **OS:** NixOS 26.05
- **Compositor:** Niri (Wayland)
- **Display Manager:** greetd + tuigreet
- **Terminal:** Alacritty
- **Shell:** Fish + Starship
- **Launcher:** Fuzzel
- **Bar:** Waybar
- **Notifications:** Mako
- **Lock Screen:** Swaylock
- **File Manager:** Thunar / Yazi (TUI)

## Theme: Midnight Ember

| Role | Color |
|------|-------|
| Background | `#0d1117` |
| Surface | `#161b22` |
| Border | `#30363d` |
| Text | `#e6edf3` |
| Accent (Orange) | `#f97316` |
| Accent (Cyan) | `#22d3ee` |

## Structure

```
dotfiles/
├── config/
│   ├── niri/           # Niri compositor configs
│   ├── alacritty/      # Terminal config
│   ├── fish/           # Shell config
│   ├── fuzzel/         # Launcher config
│   ├── waybar/         # Status bar
│   ├── mako/           # Notifications
│   ├── swaylock/       # Lock screen
│   ├── swayidle/       # Idle management
│   ├── btop/           # System monitor
│   ├── cava/           # Audio visualizer
│   ├── fastfetch/      # System info
│   └── yazi/           # File manager
├── local/
│   └── bin/            # Custom scripts
├── nixos/
│   └── configuration.nix
└── install.sh          # Symlink installer
```

## Installation

```bash
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/Dev/dotfiles
cd ~/Dev/dotfiles
./install.sh
```

## Key Bindings (Niri)

| Key | Action |
|-----|--------|
| `Super+Space` | Fuzzel launcher |
| `Super+Return` | Terminal |
| `Super+B` | Browser |
| `Super+E` | File manager |
| `Super+W` | Close window |
| `Super+F` | Fullscreen |
| `Super+1-9` | Switch workspace |
| `Super+Shift+1-9` | Move to workspace |
| `Super+Ctrl+N` | Night mode toggle |
| `Super+Ctrl+R` | Reload config |

## Scripts

- `night-mode` - Blue light filter toggle
- `screenrecord` - Screen recording with NVENC
- `toggle-mode` - Vibe/Focus mode switch
- `webapp-install` - Create web app shortcuts
- `webapp-remove` - Remove web apps
- `webapp-list` - List installed web apps
