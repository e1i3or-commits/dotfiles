# Dotfiles — Event Horizon

My NixOS + Niri rice. Theme: **Event Horizon** (Horizon Dark — warm peachy cream on deep plum, with a bright teal accent).

![theme](https://img.shields.io/badge/theme-Event%20Horizon-3fc4de)
![compositor](https://img.shields.io/badge/compositor-Niri-26bbd9)
![os](https://img.shields.io/badge/os-NixOS%2026.05-e95678)

## Stack

| Layer | Tool |
|-------|------|
| OS | NixOS 26.05 (flakes + Home Manager) |
| Compositor | Niri (Wayland, scrollable-tiling) |
| Display Manager | greetd + tuigreet |
| Bar | Waybar |
| Notifications | swaync |
| Launcher | fuzzel |
| Lock Screen | swaylock |
| Idle Manager | swayidle |
| Logout Menu | wlogout |
| OSD (volume/brightness) | swayosd |
| Terminal | Alacritty (primary), Kitty (special surfaces like cava panel) |
| Shell | Fish + Starship |
| File Manager | Thunar (GUI), Yazi (TUI) |
| System Monitor | btop |
| Audio Visualizer | cava |
| System Info | fastfetch |
| Media | mpv (with shaders) |

## Theme: Event Horizon (Horizon Dark)

| Token | Hex | Role |
|-------|-----|------|
| Background | `#1c1e26` | Window backgrounds, base |
| Foreground | `#fadad1` | Primary text (warm peachy cream) |
| Accent | `#26bbd9` | Focus rings, selection |
| Active Border | `#3fc4de` | Focused window borders |
| Red | `#e95678` | Errors, critical alerts |
| Green | `#29d398` | Git staged, success, strings |
| Pink/Magenta | `#ee64ac` | Warnings, types, notifications |
| Cyan | `#59e3e3` | Operators, hints |
| Muted | `#6c6f93` | Comments, inactive, borders |

## Structure

```
dotfiles/
├── config/
│   ├── niri/         # Niri compositor: inputs, outputs, layout, keybinds
│   ├── waybar/       # Status bar
│   ├── swaync/       # Notifications + control center
│   ├── fuzzel/       # Launcher
│   ├── swaylock/     # Lock screen
│   ├── swayidle/     # Idle management
│   ├── wlogout/      # Logout menu
│   ├── swayosd/      # Volume/brightness OSD
│   ├── alacritty/    # Primary terminal
│   ├── kitty/        # Secondary terminal (cava panel)
│   ├── yazi/         # TUI file manager
│   ├── btop/         # System monitor
│   ├── cava/         # Audio visualizer
│   ├── fastfetch/    # System info
│   ├── mpv/          # Video player (with shader stack)
│   ├── fish/         # Shell (legacy copy; primary is nix-managed)
│   └── starship.toml # Prompt
├── local/
│   └── bin/          # Custom scripts (see below)
├── nixos/
│   └── configuration.nix  # Reference system config
├── HOTKEYS.md        # Niri keybinds cheatsheet
└── install.sh        # Symlink installer
```

## Scripts

| Script | Purpose |
|--------|---------|
| `rice-demo` | Autonomous Event Horizon walkthrough — drives niri, yazi, fuzzel, etc. via tmux for screen recordings |
| `screenshot` | Grim + slurp wrapper. `--image` copies as PNG (for pasting in apps); `--file` copies as file URI (for pasting in Thunar) — works around Wayland single-MIME-type clipboard |
| `screenrecord` | Screen recording with AMD VAAPI encoding |
| `night-mode` | Blue light filter toggle |
| `toggle-mode` | Switch between focus and ambient modes |
| `keylight` | Elgato Key Light Air control |

## Installation

```bash
git clone https://github.com/e1i3or-commits/dotfiles.git ~/Dev/dotfiles
cd ~/Dev/dotfiles
./install.sh
```

The full NixOS system flake (hardware config, packages, Home Manager integration) lives in a private repo — this repo is the portable rice subset.

## Keybinds

See [`HOTKEYS.md`](HOTKEYS.md) for the full reference. Highlights:

| Key | Action |
|-----|--------|
| `Super+Space` | Launcher (fuzzel) |
| `Super+Return` | Terminal |
| `Super+E` | File manager (Thunar) |
| `Super+Shift+S` | Screenshot (→ image clipboard) |
| `Super+Ctrl+S` | Screenshot (→ file clipboard) |
| `Super+Ctrl+R` | Reload niri config |
| `Super+W` | Close window |
| `Super+1-9` | Switch workspace |

## Hardware

- CPU: AMD Ryzen 9 7900X (Raphael iGPU)
- GPU: AMD Radeon RX 7900 XT (dGPU — niri renders here)
- Displays: MSI MPG 491C 5120×1440 QD-OLED @ 144Hz + Samsung LC34G55T 3440×1440 @ 100Hz (rotated)

Niri's `render-drm-device` is explicitly pinned to the dGPU; without it you get mouse lag from cross-GPU frame copying.
