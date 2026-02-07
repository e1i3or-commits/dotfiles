# NixOS Configuration Changes - 2026-01-21

**Session Focus:** Performance optimization, NVIDIA + Wayland improvements, Quickshell fixes, Firefox PWA setup

---

## Summary

Diagnosed system lag issues (mouse freezing, high CPU usage) and applied configuration fixes to improve NVIDIA GPU utilization, memory management, and Electron/browser performance.

### Changes Overview

| Priority | Change | Status |
|----------|--------|--------|
| Quick Fix | NVIDIA open driver (`open = true`) | Needs reboot |
| Quick Fix | nvidia-vaapi-driver | Installed |
| Quick Fix | Session variables (Electron/Firefox) | Needs re-login |
| Quick Fix | ZRAM (15GB, lz4) | Active |
| Quick Fix | Remove duplicate fonts | Done |
| Quick Fix | Brave GPU flags | Needs Brave restart |
| High | Nix settings (auto-optimise, max-jobs=24) | Active |
| High | Boot loader limit (10 generations) | Active |
| Medium | Tmpfs /tmp (16GB) | Active |
| Medium | Xanmod kernel 6.18.5 | Needs reboot |
| Quick Fix | Qt Quick flickering fix (QSG vars) | Needs re-login |
| Quick Fix | firefoxpwa CLI added | Needs rebuild |

---

## Issues Diagnosed

### Root Causes of Lag
1. **Brave browser using SwiftShader** (software rendering) instead of GPU
2. **YouTube Music (pear-desktop)** consuming 100% CPU
3. **No ZRAM configured** for memory pressure handling
4. **Missing VA-API driver** for hardware video decode
5. **Electron apps not using Wayland** properly

### Problem Processes Identified
| Process | CPU Usage | Issue |
|---------|-----------|-------|
| Brave (PID 7898) | 260%+ | Software rendering, heavy JS tab |
| YouTube Music | 100% | Electron app stuck |
| Google Meet tab | ~15% | Video encoding on CPU |

---

## Changes Applied

### 1. NVIDIA Open Kernel Module

**File:** `configuration-noflake.nix` (line 94)

```nix
# Before
hardware.nvidia.open = false;

# After
hardware.nvidia.open = true;  # Use open kernel module for RTX 4070 Ti Super (Ada Lovelace)
```

**Reason:** RTX 40-series (Ada Lovelace) GPUs work better with the open kernel module. Required since driver 560+.

---

### 2. Hardware Video Acceleration (VA-API)

**File:** `configuration-noflake.nix` (lines 86-88)

```nix
hardware.graphics.extraPackages = with pkgs; [
  nvidia-vaapi-driver  # Hardware video acceleration
];
```

**Reason:** Enables hardware video decode/encode for browsers and media players, reducing CPU load.

---

### 3. Additional Session Variables

**File:** `configuration-noflake.nix` (lines 106-107)

```nix
environment.sessionVariables = {
  # ... existing variables ...
  ELECTRON_OZONE_PLATFORM_HINT = "wayland";  # Better Electron app support
  MOZ_ENABLE_WAYLAND = "1";                   # Firefox native Wayland
};
```

**Reason:** Ensures Electron apps (VS Code, Discord, Spotify, etc.) and Firefox use native Wayland instead of XWayland.

---

### 4. ZRAM Swap Configuration

**File:** `configuration-noflake.nix` (lines 420-425)

```nix
zramSwap = {
  enable = true;
  algorithm = "lz4";      # Fast compression, low CPU overhead
  memoryPercent = 50;     # Use up to 50% of RAM for compressed swap
};
```

**Reason:** Provides compressed RAM-based swap for better memory pressure handling. With 32GB RAM, this gives ~15GB of compressed swap space with minimal CPU overhead.

---

### 5. Removed Duplicate Font Declarations

**File:** `configuration-noflake.nix`

Fonts were declared in both `environment.systemPackages` and `fonts.packages`. Removed from systemPackages and consolidated in `fonts.packages`:

```nix
fonts.packages = with pkgs; [
  noto-fonts
  noto-fonts-cjk-sans
  noto-fonts-color-emoji
  font-awesome
  material-design-icons    # Added (was only in systemPackages)
  material-symbols         # Added (was only in systemPackages)
  nerd-fonts.fira-code
  nerd-fonts.jetbrains-mono
  nerd-fonts.meslo-lg
];
```

---

### 6. Brave Browser Flags

**File:** `~/.config/brave-flags.conf` (new file)

```
--enable-gpu-rasterization
--enable-zero-copy
--ignore-gpu-blocklist
--ozone-platform=wayland
--disable-features=VaapiVideoDecoder,VaapiVideoEncoder
```

**Reason:** Enables GPU rasterization for page rendering while disabling VA-API video decode (which was causing video call lag). This is a compromise - GPU helps with general browsing, but video stays on CPU to avoid call issues.

---

### 7. Nix Settings Optimization (High Priority)

**File:** `configuration-noflake.nix` (lines 403-410)

```nix
nix.settings = {
  experimental-features = [ "nix-command" "flakes" ];  # Modern nix CLI
  auto-optimise-store = true;                          # Deduplicate files in store
  max-jobs = "auto";                                   # Parallel builds (auto = 24 on this CPU)
  cores = 0;                                           # Use all cores per derivation
  trusted-users = [ "root" "kaika" ];                  # Allow binary cache usage
};
```

**Reason:** Faster builds via parallelization, smaller Nix store via deduplication, modern `nix` command available.

---

### 8. Bootloader Tweaks (High Priority)

**File:** `configuration-noflake.nix` (lines 15-18)

```nix
boot.loader.systemd-boot.configurationLimit = 10;  # Keep only 10 generations
boot.loader.timeout = 3;                            # 3 second boot menu timeout
```

**Reason:** Cleaner boot menu, slightly faster boot sequence.

---

### 9. Xanmod Kernel (Medium Priority)

**File:** `configuration-noflake.nix` (line 21)

```nix
boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;
```

**Reason:** Xanmod kernel provides better desktop/gaming performance with improved scheduler (BORE), lower latency, and optimizations for modern hardware.

**Kernel version:** 6.18.5-xanmod1 (up from stock 6.12.65)

---

### 10. Tmpfs for /tmp (Medium Priority)

**File:** `configuration-noflake.nix` (lines 24-27)

```nix
boot.tmp = {
  useTmpfs = true;
  tmpfsSize = "50%";  # Up to 50% of RAM (16GB)
};
```

**Reason:** Faster builds and compilation (temp files in RAM), reduced SSD wear, automatic cleanup on reboot.

---

## Verification

After rebuild, verified:

```bash
# ZRAM active
$ zramctl
NAME       ALGORITHM DISKSIZE DATA COMPR TOTAL STREAMS MOUNTPOINT
/dev/zram0 lz4          15.2G   4K   69B   20K      24 [SWAP]

# Session variables set
$ env | grep -E '(ELECTRON|MOZ_ENABLE)'
ELECTRON_OZONE_PLATFORM_HINT=auto
MOZ_ENABLE_WAYLAND=1

# Nix settings applied
$ nix show-config | grep -E '(auto-optimise|max-jobs|cores)'
auto-optimise-store = true
cores = 0
max-jobs = 24

# Tmpfs /tmp active
$ mount | grep "on /tmp"
tmpfs on /tmp type tmpfs (rw,nosuid,nodev,size=15984304k)

$ df -h /tmp
Filesystem      Size  Used Avail Use% Mounted on
tmpfs            16G  4.0K   16G   1% /tmp

# Boot entries limited to 10
$ ls /boot/loader/entries/ | wc -l
10
```

---

## Post-Change Actions Required

1. **Reboot** - Required for:
   - NVIDIA open kernel module
   - Xanmod kernel 6.18.5
   - Full session variable activation
2. **Restart Brave** - To apply brave-flags.conf
3. **Verify GPU acceleration** - Check `brave://gpu` after restart

---

## Future Considerations

### Not Changed (Deliberate)
- **Flakes:** Kept channel-based setup due to previous niri-flake build failures
- **Config modularization:** Single-file approach works fine for current needs
- **VA-API in browser:** Disabled due to video call lag issues

### Potential Future Improvements
- Consider `hardware.nvidia.powerManagement.enable = true` if power consumption is a concern
- Monitor if nvidia-vaapi-driver improves enough to re-enable in Brave
- Workspace naming rules in niri config (from TO_DO.md)
- Night mode keybind setup with wlsunset (from TO_DO.md)

---

## Commands Reference

```bash
# Apply config changes
sudo cp "/home/kaika/Dev/Nix Config/configuration-noflake.nix" /etc/nixos/configuration.nix
sudo nixos-rebuild switch

# Check ZRAM status
zramctl

# Check GPU status
nvidia-smi

# Check Brave GPU acceleration
# Open brave://gpu in browser

# Monitor system resources
btop
```

---

## Research Notes

Based on NixOS best practices research (2025-2026):

- **NVIDIA + Wayland:** Driver 555+ recommended for explicit sync support
- **ZRAM:** lz4 algorithm recommended for 99% of use cases (fast, low CPU)
- **Electron apps:** `ELECTRON_OZONE_PLATFORM_HINT=wayland` is the modern approach
- **Open kernel module:** Required for Turing+ GPUs since driver 560

---

---

## Session 2: Quickshell Flickering Fix & Firefox PWA Setup

### 11. Fix Quickshell/DMS Window Flickering (REVERTED)

**Status:** REVERTED on 2026-01-22 - caused gray screen refresh every 30 seconds

**File:** `~/.config/niri/config.kdl` (environment block)

```kdl
environment {
    // ... existing variables ...

    // Fix Qt Quick flickering on NVIDIA
    QSG_RENDER_LOOP "basic"  // Single-threaded render loop - fixes flickering
    QSG_RHI_BACKEND "vulkan"  // Use Vulkan for better NVIDIA sync
    __GL_SYNC_TO_VBLANK "1"   // Force vsync for OpenGL surfaces
}
```

**Issue:** Visual flickering on windows, especially unfocused ones, when using DMS (quickshell-based shell) with NVIDIA.

**Root Cause:** Qt Quick's threaded render loop doesn't synchronize properly with NVIDIA's Wayland implementation.

**Solution (attempted):**
- `QSG_RENDER_LOOP=basic` - Forces single-threaded Qt Quick rendering
- `QSG_RHI_BACKEND=vulkan` - Uses Vulkan backend for better frame sync
- `__GL_SYNC_TO_VBLANK=1` - Forces vsync on OpenGL surfaces

**Why Reverted:** These variables caused the compositor to refresh/redraw the entire screen every ~30 seconds, showing a gray flash. The actual fix was disabling VRR and switching to NVIDIA open kernel module. See CHANGELOG-2026-01-22.md.

---

### 12. Firefox PWA (Web Apps) Setup

**File:** `configuration-noflake.nix`

```nix
environment.systemPackages = with pkgs; [
  # ...
  firefoxpwa      # CLI tool for creating Firefox web apps
];
```

**Reason:** Switched from Brave to Firefox. Added `firefoxpwa` CLI to system packages (was only configured as native messaging host, CLI wasn't in PATH).

**Web Apps to Create:**
```bash
firefoxpwa site install https://messages.google.com/web/u/1/conversations --name "Google Messages"
firefoxpwa site install https://web.whatsapp.com --name "WhatsApp"
firefoxpwa site install https://cliq.zoho.com --name "Cliq"
```

**Note:** Requires Firefox PWA extension: https://addons.mozilla.org/firefox/addon/pwas-for-firefox/

---

## Post-Session 2 Actions

1. **Rebuild NixOS** - `sudo nixos-rebuild switch` (for firefoxpwa CLI)
2. **Log out/in** - To apply Qt environment variables for quickshell
3. **Install Firefox PWA extension** - Then create webapps with commands above

---

*Changes applied: 2026-01-21*
*NixOS Version: 26.05pre (unstable)*
*Hardware: AMD Ryzen 9 7900X, NVIDIA RTX 4070 Ti Super, 32GB RAM*
