# NixOS Setup Session - Configuration Summary

**Initial Setup:** 2026-01-16
**Last Updated:** 2026-01-17
**Status:** ✅ INSTALLED AND WORKING

---

## Current System

### NixOS Version
- **Version:** 26.05pre (unstable)
- **Configuration:** Non-flake (channels)
- **Home Manager:** Integrated via `<home-manager/nixos>`

### Hardware
- **CPU:** AMD (kvm-amd support)
- **GPU:** NVIDIA (proprietary drivers)
- **Drives:**
  - nvme0n1 (2TB) - Root
  - nvme1n1 (1TB) - /home
  - nvme2n1 (1TB) - Backups

---

## Configuration Architecture

### Active Setup (Non-Flake)

Uses NixOS channels instead of flakes for simplicity and stability.

**Main Config File:** `configuration-noflake.nix`
- Contains all system configuration
- Home Manager config embedded inline
- Copied to `/etc/nixos/configuration.nix`

**Channels Used:**
- `nixos` → nixos-unstable
- `home-manager` → home-manager master

### Why Non-Flake?
- Niri flake had build failures (test failures in sandbox)
- Simpler to maintain and debug
- All packages available in nixpkgs unstable
- DankMaterialShell available as `programs.dms-shell.enable`

---

## Desktop Environment

### Components
- **Compositor:** Niri (scrollable-tiling Wayland)
- **Desktop Shell:** DankMaterialShell (`programs.dms-shell.enable = true`)
- **Display Manager:** GDM with Wayland
- **Terminal:** Alacritty
- **User Shell:** Fish

### Niri Configuration
- Config location: `~/.config/niri/config.kdl`
- Template available: `niri/config-danklinux.kdl`
- Reload command: `niri msg action load-config-file`

---

## Installed Software

### Development
- VSCode (with extensions via Home Manager)
- Node.js 22 + pnpm
- Python 3 + pip
- Docker (rootless mode)
- Git + Lazygit

### CLI Tools
- bat, eza, ripgrep, fd, zoxide, fzf, jq, htop, btop

### Applications
- **Browser:** Brave
- **Office:** LibreOffice
- **Notes:** Obsidian
- **Creative:** GIMP, Krita, Inkscape, OBS Studio
- **Media:** VLC, Spotify
- **Files:** Thunar
- **Cloud:** Nextcloud client
- **Passwords:** Bitwarden
- **Backups:** Timeshift

### Virtualization
- Docker (rootless)
- libvirt + QEMU + virt-manager

---

## Special Configuration

### nix-ld (FHS Compatibility)
Fixes "exit code 127" errors for prebuilt binaries like Claude Code:
```nix
programs.nix-ld.enable = true;
systemd.tmpfiles.rules = [
  "L+ /lib64/ld-linux-x86-64.so.2 - - - - ${realLd}"
  "L+ /lib/ld-linux-x86-64.so.2 - - - - ${realLd}"
];
```

### NVIDIA + Wayland
```nix
hardware.nvidia = {
  modesetting.enable = true;
  open = false;  # proprietary drivers
  package = config.boot.kernelPackages.nvidiaPackages.stable;
};
environment.sessionVariables = {
  NIXOS_OZONE_WL = "1";
  WLR_NO_HARDWARE_CURSORS = "1";
  GBM_BACKEND = "nvidia-drm";
  __GLX_VENDOR_LIBRARY_NAME = "nvidia";
};
```

### VSCode Settings
- Extensions managed by Home Manager
- Settings.json managed by VS Code UI (not Nix)
- Allows Claude Code extension to save settings

---

## File Structure

```
/home/kaika/Dev/Nix Config/
├── configuration-noflake.nix  # MAIN CONFIG (active)
├── hardware-configuration.nix # Auto-generated
├── niri/
│   ├── config.kdl             # User niri config
│   └── config-danklinux.kdl   # DankLinux template
├── README.md                  # Quick reference
├── POST_INSTALL_CHECKLIST.md  # Setup checklist
├── NIXOS_SETUP_SESSION.md     # This file
│
├── flake.nix                  # DEPRECATED (not used)
├── configuration.nix          # DEPRECATED (not used)
└── home.nix                   # DEPRECATED (not used)
```

---

## Common Commands

```bash
# Rebuild system
sudo nixos-rebuild switch

# Update and rebuild
sudo nix-channel --update && sudo nixos-rebuild switch

# Rollback
sudo nixos-rebuild switch --rollback

# Cleanup
sudo nix-collect-garbage -d

# Reload Niri config
niri msg action load-config-file

# Validate Niri config
niri validate ~/.config/niri/config.kdl
```

---

## User Settings

### Account
- **Username:** kaika
- **Groups:** networkmanager, wheel, video, audio, docker
- **Shell:** Fish

### Git Config
- **Name:** kaika
- **Email:** kaikaapro.com (note: missing @ - may need fix)

### Session Variables
- EDITOR=code
- VISUAL=code
- TERMINAL=alacritty
- BROWSER=brave

---

## Known Issues / Notes

1. **Git email** - Currently set to `kaikaapro.com` (missing @)
2. **Pear Music** - Not installed (not in nixpkgs)
3. **Zoho Cliq** - Use web version
4. **WhatsApp** - Use web version

---

## Installation History

### 2026-01-16
- Initial NixOS installation
- Created flake-based configuration

### 2026-01-17
- Switched to non-flake (channels) due to niri-flake build failures
- Added DankMaterialShell via `programs.dms-shell.enable`
- Added nix-ld for FHS compatibility
- Fixed VS Code settings management
- Updated all documentation

---

## Resources

- **NixOS Manual:** https://nixos.org/manual/nixos/stable/
- **Home Manager:** https://nix-community.github.io/home-manager/
- **Niri Wiki:** https://github.com/YaLTeR/niri/wiki
- **DankLinux:** https://danklinux.com/docs/
- **Fish Shell:** https://fishshell.com/docs/current/

---

*Status: System fully operational*
