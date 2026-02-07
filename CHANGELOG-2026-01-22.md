# NixOS Configuration Changes - 2026-01-22

**Session Focus:** Stability fixes for NVIDIA + Quickshell/DMS crashes, VRR flickering, Qt rendering issues

---

## Summary

Continued debugging system instability issues related to NVIDIA driver interaction with Quickshell/DMS (Qt Quick-based desktop shell) on Wayland. Fixed multiple issues including window flickering, gray screen refresh, and system crashes.

### Changes Overview

| Priority | Change | Status |
|----------|--------|--------|
| Critical | Remove Qt environment variables from niri | Done |
| Critical | Disable VRR (Variable Refresh Rate) | Done |
| Critical | Switch to NVIDIA open kernel module | Done |
| Critical | Force niri to render on NVIDIA GPU | Done |
| Medium | btop config with GPU monitoring | Done |
| Low | Change file manager hotkey to Yazi | Done |

---

## Issues Diagnosed & Fixed

### 1. Window Flickering (VRR Issue)

**Symptom:** Windows flickering, especially on focus changes.

**Root Cause:** VRR (Variable Refresh Rate) enabled on NVIDIA causing vblank synchronization issues.

**Fix:** Disabled VRR in niri config, set fixed refresh rate.

**File:** `~/.config/niri/config.kdl`

```kdl
output "DP-2" {
    // VRR disabled - causes flickering on NVIDIA
    mode "5120x1440@119.999"
    scale 1.25
}
```

---

### 2. Gray Screen Refresh Every 30 Seconds

**Symptom:** Background going gray momentarily every ~30 seconds, then reloading.

**Root Cause:** Qt environment variables (`QSG_RENDER_LOOP`, `QSG_RHI_BACKEND`, `__GL_SYNC_TO_VBLANK`) added to fix flickering were causing compositor refresh issues.

**Fix:** Removed these variables from niri config. Required full logout/login to clear from session.

**File:** `~/.config/niri/config.kdl`

```kdl
// REMOVED - caused gray screen refresh:
// QSG_RENDER_LOOP "basic"
// QSG_RHI_BACKEND "vulkan"
// __GL_SYNC_TO_VBLANK "1"
// __GL_MaxFramesAllowed "1"
```

**Note:** These variables persist in the session even after removing from config. Must logout/login to clear them.

---

### 3. System Crash (White Screen)

**Symptom:** System froze with bright white screen, required hard restart.

**Root Cause:** Quickshell/DMS spawned a flood of shell processes (~30+ in 2 seconds), overwhelming the compositor. Logs showed:
```
libinput error: event0 - Logitech MX Master 2S: client bug: event processing lagging behind by 187ms, your system is too slow
```

**Investigation:** Journal showed dozens of `app-niri-sh-*` scopes spawned at 08:40:28-30, causing input lag and eventual crash.

**Fix (Testing):** Switched to NVIDIA open kernel module (`open = true`), which is officially recommended for RTX 40-series GPUs.

**File:** `configuration-noflake.nix`

```nix
# Before
hardware.nvidia.open = false;  # Proprietary driver

# After
hardware.nvidia.open = true;  # Open kernel module (recommended for RTX 40-series)
```

---

### 4. Thunar High CPU Usage

**Symptom:** Thunar file manager causing 60% CPU usage when opened.

**Root Cause:** Thumbnail generation getting stuck.

**Fix:** Changed default file manager hotkey to Yazi (terminal-based).

**File:** `~/.config/niri/config.kdl`

```kdl
Mod+Shift+F { spawn "kitty" "yazi"; }  // Changed from "thunar"
```

---

### 5. btop GPU Monitoring

**Issue:** btop not showing GPU information.

**Fix:** Created btop config with GPU monitoring enabled.

**File:** `~/.config/btop/btop.conf`

```ini
show_gpu_info = "On"
gpu_mirror_graph = true
custom_gpu_name0 = "RTX 4070 Ti Super"
```

---

### 6. Force Niri to Render on NVIDIA GPU (INPUT LAG FIX)

**Symptom:** Mouse sticking/lagging, screenshots triggering early during drag, general input delay.

**Root Cause:** System has two GPUs:
- card1 (renderD128) = NVIDIA RTX 4070 Ti Super (display connected here)
- card2 (renderD129) = AMD Radeon (Ryzen 9 7900X integrated graphics)

Niri was potentially rendering on the AMD iGPU while the display was connected to NVIDIA, causing frame copying between GPUs and input latency.

**Fix:** Force niri to use NVIDIA GPU for rendering.

**File:** `~/.config/niri/config.kdl`

```kdl
debug {
    // Force niri to use NVIDIA GPU (card1) instead of AMD iGPU (card2)
    render-drm-device "/dev/dri/card1"
}
```

**Result:** Input lag completely resolved.

**Reference:** [Niri Issue #3095](https://github.com/YaLTeR/niri/issues/3095)

---

## Technical Details

### NVIDIA Driver Versions
- Driver: 580.119.02
- Kernel module: Switching from proprietary to open

### Environment Variables (Current)
```bash
# Set in NixOS config (still active)
GBM_BACKEND=nvidia-drm
__GLX_VENDOR_LIBRARY_NAME=nvidia
LIBVA_DRIVER_NAME=nvidia

# REMOVED from niri config (were causing issues)
# QSG_RENDER_LOOP=basic
# QSG_RHI_BACKEND=vulkan
# __GL_SYNC_TO_VBLANK=1
```

### Crash Timeline (08:40)
1. 08:40:28 - Flood of `app-niri-sh-*` scopes spawned
2. 08:40:28 - libinput reports 187ms input lag
3. 08:40:30 - Timer expiry warnings (system too slow)
4. Shortly after - White screen crash

---

## Post-Change Actions Required

1. **Copy config and rebuild:**
   ```bash
   sudo cp "/home/kaika/Dev/Nix Config/configuration-noflake.nix" /etc/nixos/configuration.nix
   sudo nixos-rebuild switch
   ```

2. **Reboot** - Required for NVIDIA open kernel module change

3. **Monitor stability** - Watch for:
   - Window flickering
   - Gray screen refresh
   - System crashes
   - Mouse/input lag

---

## Potential Next Steps (If Issues Persist)

1. **Disable Quickshell/DMS entirely** - Use Waybar instead
2. **Try different Qt Quick settings** - If open driver doesn't help
3. **Report to DMS/Quickshell upstream** - Qt Quick + NVIDIA Wayland issue

---

## Hardware Reference

- **CPU:** AMD Ryzen 9 7900X (24 threads)
- **GPU:** NVIDIA RTX 4070 Ti Super (Ada Lovelace)
- **RAM:** 32GB
- **Monitor:** Samsung Odyssey G9 (5120x1440@120Hz)
- **Mouse:** Logitech MX Master 2S

---

*Changes applied: 2026-01-22*
*NixOS Version: 26.05pre (unstable)*
*Niri Version: Latest from nixpkgs*
*NVIDIA Driver: 580.119.02*
