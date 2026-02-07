# Deprecated Configuration Files

These files are from an earlier flake-based setup that was replaced with a non-flake (channels) approach.

## Why Deprecated?

The niri-flake had build failures due to test failures in the NixOS sandbox environment. Switching to the non-flake approach using NixOS channels resolved all issues.

## Files

- `flake.nix` - Original flake configuration
- `configuration.nix` - Original system config (flake version)
- `home.nix` - Separate Home Manager config (now embedded in main config)

## Current Setup

The active configuration is now `configuration-noflake.nix` in the parent directory, which:
- Uses NixOS channels (nixos-unstable, home-manager master)
- Has Home Manager config embedded inline
- Includes nix-ld for FHS compatibility
- Enables DankMaterialShell via `programs.dms-shell.enable`

## Restoration

If you ever want to switch back to flakes, these files can be restored. However, note that the niri-flake build issues may still exist.

---

*Archived: 2026-01-17*
