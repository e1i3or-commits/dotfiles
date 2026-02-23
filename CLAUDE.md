# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

NixOS desktop configuration ("Frost Peak") for a dual-AMD-GPU system (RX 7900 XT + Raphael iGPU) running Niri (Wayland compositor) with Noctalia Shell. Uses Nix flakes + Home Manager.

The primary config lives in `Nix Config/` (git repo, remote: `git@github.com:e1i3or-commits/dotfiles.git`). The `~/nix-config` symlink points here.

## Build Commands

```fish
# Rebuild system (permanent) — use after editing .nix files
nrs   # alias for: sudo nixos-rebuild switch --flake ~/nix-config#nixos

# Rebuild system (test only, reverts on reboot)
nrt   # alias for: sudo nixos-rebuild test --flake ~/nix-config#nixos

# Update all flake inputs
nix flake update ~/nix-config

# Rollback to previous generation
sudo nixos-rebuild switch --rollback
```

## What Needs Rebuild vs What's Live

**Requires `nrs`:** `configuration.nix`, `home/default.nix`, `flake.nix`

**Live-editable (symlinked via `mkOutOfStoreSymlink`):**
- `config/niri/` — reload with `Mod+Ctrl+R` or `niri msg action load-config-file`
- `config/waybar/`, `config/fish/`, `config/fuzzel/`, `config/mako/`, `config/swaylock/`, `config/swayidle/`, `config/cava/`, `config/fastfetch/`, `config/yazi/`, `config/alacritty/`, `config/starship.toml`
- `local/bin/` scripts — immediately available
- `thunderbird/` CSS files

The symlink chain: `~/.config/app` → nix store → `mkOutOfStoreSymlink` → `~/nix-config/config/app` (actual files here).

## Architecture

```
Nix Config/
├── flake.nix                  # Inputs: nixpkgs-unstable, home-manager, noctalia-shell
├── configuration.nix          # System: boot, GPU, services, packages, security
├── hardware-configuration.nix # Auto-generated: LUKS, filesystems (don't edit)
├── home/default.nix           # User: programs, dotfile symlinks, Noctalia config
├── config/                    # Live-editable dotfiles (symlinked to ~/.config/)
│   └── niri/config.kdl        # Compositor: inputs, outputs, layout, keybinds, debug
├── local/bin/                 # Custom scripts (symlinked to ~/.local/bin/)
└── scripts/                   # Python utilities (email organization)
```

**Two-tier config pattern:** System-level in `configuration.nix` (packages, services, kernel) + user-level in `home/default.nix` (programs, dotfiles, themes). Dotfiles are symlinked out of the Nix store for live editing.

## Hardware & GPU

- **CPU:** AMD Ryzen 9 7900X (iGPU = Raphael = `renderD129` = `card0`)
- **dGPU:** AMD RX 7900 XT (Navi 31 = `renderD128` = `card1`)
- **Display 1:** Samsung LC49G95T 5120x1440@120Hz (DP-3, main ultrawide)
- **Display 2:** Samsung LC34G55T 3440x1440@100Hz (DP-2, rotated 90°)

Niri is forced to render on the dGPU via `render-drm-device "/dev/dri/renderD128"` in the debug section of `config/niri/config.kdl`. If this is wrong, you get mouse lag / input latency from cross-GPU frame copying.

GPU device numbering can change between kernel updates — verify with:
```bash
ls -l /sys/class/drm/card*/device/driver  # which driver
cat /sys/class/drm/card*/device/uevent    # PCI IDs
```

## Known Recurring Issues

**Mouse lag:** Usually caused by Niri rendering on the iGPU instead of the dGPU. Verify `render-drm-device` points to the RX 7900's renderD device. Can also be caused by `disable-cursor-plane` (forces software cursor — remove unless needed). Check `journalctl -f | grep libinput` for lag warnings.

**DP-2 black screen on boot:** Workaround in niri config: `spawn-at-startup "sh" "-c" "sleep 2 && niri msg output DP-2 off && sleep 1 && niri msg output DP-2 on"`

**Process floods from Quickshell/Noctalia:** Can spawn excessive shell processes and starve the compositor. Check with `ps aux | grep quickshell`.

## Theme: Frost Peak

| Token | Hex | Usage |
|-------|-----|-------|
| Primary | `#38bdf8` | Focus rings, accents, active borders |
| Secondary | `#a78bfa` | Git branch, module accents |
| Background | `#0c0e14` | Window backgrounds |
| Surface | `#141620` | Cards, inactive borders |
| Border | `#262a3a` | Separators |
| Text | `#e0e6f0` | Primary text |

## Key Conventions

- User: `kaika`, hostname: `nixos`
- Shell: Fish (abbreviations defined in `home/default.nix`)
- Niri keybinds use `Mod` (Super) as the primary modifier
- Noctalia Shell replaces waybar/mako/fuzzel/swaylock/swayidle/swaybg
- XWayland via `xwayland-satellite` for legacy X11 apps (Zoho WorkDrive)
- YubiKey U2F configured for sudo/greetd/swaylock (mode: "sufficient")
