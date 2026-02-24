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

**Important:** Always commit changes before running `nrs` — the flake system warns "Git tree is dirty" on uncommitted changes.

**Git email:** Use the GitHub noreply email (configured in repo): `246305258+e1i3or-commits@users.noreply.github.com`. GitHub blocks pushes with private emails.

## What Needs Rebuild vs What's Live

**Requires `nrs`:** `configuration.nix`, `home/default.nix`, `flake.nix`

**Live-editable (symlinked via `mkOutOfStoreSymlink`):**
- `config/niri/` — reload with `Mod+Ctrl+R` or `niri msg action load-config-file`
- `config/waybar/`, `config/fish/`, `config/fuzzel/`, `config/mako/`, `config/swaylock/`, `config/swayidle/`, `config/cava/`, `config/fastfetch/`, `config/yazi/`, `config/alacritty/`, `config/starship.toml`
- `local/bin/` scripts — immediately available
- `thunderbird/` CSS files

The symlink chain: `~/.config/app` → nix store → `mkOutOfStoreSymlink` → `~/nix-config/config/app` (actual files here).

**When adding new scripts to `local/bin/`:** You must also add a symlink entry in `home/default.nix` under `home.file` using `mkOutOfStoreSymlink`, then rebuild. Without this, the script won't appear in `~/.local/bin/`.

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
- **Mouse:** Logitech MX Master 2S via Unifying Receiver (USB `046d:c52b`)

Niri is forced to render on the dGPU via `render-drm-device "/dev/dri/renderD128"` in the debug section of `config/niri/config.kdl`. If this is wrong, you get mouse lag / input latency from cross-GPU frame copying.

GPU device numbering can change between kernel updates — verify with:
```bash
ls -l /sys/class/drm/card*/device/driver  # which driver
cat /sys/class/drm/card*/device/uevent    # PCI IDs
```

## Known Recurring Issues

**Mouse lag:** Multiple possible causes, check in order:
1. **Wrong render device:** Verify `render-drm-device` in niri debug section points to the RX 7900's renderD device (currently `renderD128`). Cross-GPU frame copying causes input latency.
2. **`disable-cursor-plane`:** Do NOT use on AMD — forces software cursor through compositor. Only needed for NVIDIA.
3. **Logitech HID++ errors:** Check `journalctl -k -b | grep hidpp`. If receiver lost permissions, run `sudo udevadm trigger --action=add /dev/hidraw0 /dev/hidraw1`. Solaar manages device settings.
4. **PCIe ASPM:** Must stay disabled (`pcie_aspm=off` in kernel params). Re-enabling causes GPU stutter.
5. **libinput lag:** Check `journalctl -f | grep libinput` for "event processing lagging" warnings — indicates compositor starvation (usually from Quickshell process floods).

**DP-2 black screen on boot:** Workaround in niri config: `spawn-at-startup "sh" "-c" "sleep 2 && niri msg output DP-2 off && sleep 1 && niri msg output DP-2 on"`

**Process floods from Quickshell/Noctalia:** Can spawn excessive shell processes and starve the compositor. Check with `ps aux | grep quickshell`.

**Solaar not detecting devices:** hidraw permissions issue. After plugging receiver into a new USB port, run `sudo udevadm trigger --action=add /dev/hidraw0 /dev/hidraw1` to re-apply udev rules.

## Wayland Clipboard Limitations

`wl-copy` can only serve **one MIME type** at a time. The `screenshot` script (`local/bin/screenshot`) works around this with two modes:
- `screenshot` / `screenshot --image` — copies as `image/png` (for pasting into apps)
- `screenshot --file` — copies as `x-special/gnome-copied-files` (for pasting as file in Thunar)

Keybinds: `Mod+Shift+S` (image mode), `Mod+Ctrl+S` (file mode). Both save to `~/Pictures/Screenshots/`.

PyGObject/GTK clipboard from scripts does NOT work on Wayland without a focused surface — don't attempt the multi-MIME-type approach via Python GTK.

## NixOS Python Packaging

On NixOS, `python3Packages.foo` as a standalone system package does NOT make it importable. Use `python3.withPackages (ps: [ ps.foo ])` instead. GI typelibs also require packages like `gtk3`, `gobject-introspection`, `pango` etc. to be in the environment — the simplest approach for scripts is a `nix-shell` shebang.

## Theme: Frost Peak

| Token | Hex | Usage |
|-------|-----|-------|
| Primary | `#38bdf8` | Focus rings, accents, active borders |
| Secondary | `#a78bfa` | Git branch, module accents |
| Background | `#0c0e14` | Window backgrounds |
| Surface | `#141620` | Cards, inactive borders |
| Border | `#262a3a` | Separators |
| Text | `#e0e6f0` | Primary text |

## Zoho WorkDrive TrueSync

TrueSync runs as a FUSE mount at `/home/kaika/ZohoWorkDrive/` with on-demand file downloading. Config lives in `~/.zohoworkdrivets/`. Started via autostart desktop entry using XWayland (Qt6 app, needs `QT_QPA_PLATFORM=xcb DISPLAY=:0`).

**Context menu socket protocol** (`~/.zohoworkdrivets/zoho_teamdrive_contextmenusock`):
- Messages are length-prefixed JSON: `<10-digit-zero-padded-length><JSON>`
- Get menu: `{"getmenu":["/home/kaika/ZohoWorkDrive/FolderName"]}`
- Trigger action: `{"Available offline":["/path"]}` or `{"Online only":["/path"]}` or `{"Refresh":["/path"]}`
- Active option has checkmark: `"Online only ✔"`

**KDE plugin** (`~/.zohoworkdrivets/bin/kde_plugins/zoho_ztdrive_contextmenu.so`) is KF5/Qt5 — incompatible with KF6 Dolphin from current nixpkgs. To load it for testing, use `nix-shell -p qt5.qtbase libsForQt5.kio libsForQt5.kcoreaddons` and `KPluginFactory::create<KAbstractFileItemActionPlugin>()`.

**Database** (`~/.zohoworkdrivets/<account_id>/resources.db`): SQLite with `FileSystem` table. Status field is a bitmask — bit 2048 (0x800) = "available offline". Modifying the DB alone doesn't trigger downloads; must use the socket protocol.

## Key Conventions

- User: `kaika`, hostname: `nixos`
- Shell: Fish (abbreviations defined in `home/default.nix`)
- Niri keybinds use `Mod` (Super) as the primary modifier
- Noctalia Shell replaces waybar/mako/fuzzel/swaylock/swayidle/swaybg
- XWayland via `xwayland-satellite` for legacy X11 apps (Zoho WorkDrive)
- YubiKey U2F configured for sudo/greetd/swaylock (mode: "sufficient")
- Logitech MX Master 2S managed via Solaar (udev rules in `configuration.nix`)
