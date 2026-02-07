# Post-Install Checklist & Quick Start Guide

**After NixOS installation - Updated for non-flake setup**

---

## Immediate Post-Install Steps

### 1. Verify System Basics

```bash
# Check disk status
lsblk -f

# Verify all partitions mounted
df -h

# Check user and groups
groups kaika

# Test internet connection
ping -c 3 nixos.org
```

---

### 2. Copy Configuration to /etc/nixos

```bash
# Navigate to config directory
cd /home/kaika/Dev/Nix\ Config/

# Copy the main configuration file
sudo cp configuration-noflake.nix /etc/nixos/configuration.nix

# Verify hardware-configuration.nix exists (auto-generated during install)
ls -la /etc/nixos/hardware-configuration.nix

# Set proper ownership
sudo chown root:root /etc/nixos/*.nix
sudo chmod 644 /etc/nixos/*.nix
```

**Alternative: Create symlink for easier updates:**
```bash
sudo ln -sf /home/kaika/Dev/Nix\ Config/configuration-noflake.nix /etc/nixos/configuration.nix
```

---

### 3. Rebuild System

```bash
# Build and activate the configuration
sudo nixos-rebuild switch

# If you get errors, show detailed trace:
sudo nixos-rebuild switch --show-trace
```

---

### 4. Configure Niri

```bash
# Create config directory
mkdir -p ~/.config/niri

# Copy the DankLinux-optimized config
cp /home/kaika/Dev/Nix\ Config/niri/config-danklinux.kdl ~/.config/niri/config.kdl

# Or copy the standard config
cp /home/kaika/Dev/Nix\ Config/niri/config.kdl ~/.config/niri/config.kdl

# Validate config
niri validate ~/.config/niri/config.kdl

# Reload Niri (if already running)
niri msg action load-config-file
```

---

### 5. Reboot and Select Niri

```bash
sudo reboot
```

At login screen (GDM):
1. Click your username
2. Click the gear icon at bottom right
3. Select "Niri" from session list
4. Enter password and login

---

## Application Setup

### Nextcloud
```bash
# Launch Nextcloud client
nextcloud

# Login to your server (kaika@192.168.88.245:8080)
# Configure sync folders
```

### Bitwarden
```bash
bitwarden-desktop
# Login or create account
```

### Docker
```bash
# Verify Docker is running
docker --version
docker ps

# Test with hello-world
docker run hello-world
```

### Git SSH Key
```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "kaika@nixos"

# Add to SSH agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Copy public key
cat ~/.ssh/id_ed25519.pub | wl-copy

# Add to GitHub/GitLab
```

### Timeshift Backups
```bash
# Launch Timeshift
sudo timeshift-gtk

# Configuration:
# 1. Select RSYNC
# 2. Select backup destination drive
# 3. Configure schedule (daily/weekly)
# 4. Create first backup
```

---

## Verification Checklist

### System
- [ ] User 'kaika' can login
- [ ] Internet connection works
- [ ] Audio works (test with pavucontrol)
- [ ] Graphics acceleration working (NVIDIA)

### Desktop Environment
- [ ] Niri loads successfully
- [ ] DankMaterialShell active
- [ ] Keyboard shortcuts work
- [ ] Multiple workspaces functional

### Applications
- [ ] Alacritty terminal opens (`Mod+Return`)
- [ ] Fish shell active with abbreviations
- [ ] Brave browser works (`Mod+B`)
- [ ] VSCode opens (`Mod+C`)
- [ ] Thunar file manager works (`Mod+E`)
- [ ] wofi launcher works (`Mod+D`)

### Development
- [ ] Node.js and pnpm available
- [ ] Python 3 and pip available
- [ ] Docker running
- [ ] Git configured
- [ ] Lazygit works

### CLI Tools
- [ ] `bat` works (cat replacement)
- [ ] `eza` works (ls replacement)
- [ ] `z` works (zoxide - smart cd)
- [ ] `fzf` works (fuzzy finder)

---

## System Maintenance

```bash
# Update channels
sudo nix-channel --update

# Rebuild with updates
sudo nixos-rebuild switch

# Clean old generations
sudo nix-collect-garbage -d

# List generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Rollback
sudo nixos-rebuild switch --rollback

# Check NixOS version
nixos-version
```

---

## Troubleshooting

### Niri won't start
```bash
journalctl -u niri -b
niri validate ~/.config/niri/config.kdl
```

### Docker permission denied
```bash
# Verify docker group membership
groups kaika | grep docker

# If not in group, rebuild config and reboot
```

### Claude Code exit 127
Already fixed in config with:
- `programs.nix-ld.enable = true`
- FHS loader symlinks

### Missing packages
```bash
# Search for package
nix search nixpkgs package-name

# Add to configuration-noflake.nix, then rebuild
```

---

## Key Shortcuts Reference

| Shortcut | Action |
|----------|--------|
| `Mod+Return` | Terminal |
| `Mod+D` | App launcher |
| `Mod+Q` | Close window |
| `Mod+H/J/K/L` | Navigate |
| `Mod+Shift+H/J/K/L` | Move window |
| `Mod+1-9` | Workspaces |
| `Mod+F` | Fullscreen |
| `Mod+Ctrl+R` | Reload Niri |
| `Mod+Shift+E` | Quit Niri |

---

## Resources

- **NixOS Manual:** https://nixos.org/manual/nixos/stable/
- **Home Manager:** https://nix-community.github.io/home-manager/
- **Niri Wiki:** https://github.com/YaLTeR/niri/wiki
- **DankLinux Docs:** https://danklinux.com/docs/

---

*Updated: 2026-01-17*
