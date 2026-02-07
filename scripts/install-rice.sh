#!/usr/bin/env bash
# Midnight Ember Rice Installation Script
# Run this after: sudo nixos-rebuild switch

set -e

CONFIG_DIR="$HOME/Dev/Nix Config"
echo "🔥 Installing Midnight Ember rice..."

# Create config directories
echo "📁 Creating config directories..."
mkdir -p ~/.config/niri
mkdir -p ~/.config/waybar
mkdir -p ~/.config/wofi
mkdir -p ~/.config/mako
mkdir -p ~/.config/yazi
mkdir -p ~/.config/cava
mkdir -p ~/.config/fastfetch
mkdir -p ~/.local/bin

# Copy Niri configs
echo "📝 Installing Niri configs..."
cp "$CONFIG_DIR/niri/config-vibe.kdl" ~/.config/niri/
cp "$CONFIG_DIR/niri/config-focus.kdl" ~/.config/niri/
cp "$CONFIG_DIR/niri/config-vibe.kdl" ~/.config/niri/config.kdl
echo "vibe" > ~/.config/niri/.current-mode

# Copy Waybar
echo "📊 Installing Waybar config..."
cp "$CONFIG_DIR/waybar/config" ~/.config/waybar/
cp "$CONFIG_DIR/waybar/style.css" ~/.config/waybar/

# Copy Wofi
echo "🚀 Installing Wofi config..."
cp "$CONFIG_DIR/wofi/config" ~/.config/wofi/
cp "$CONFIG_DIR/wofi/style.css" ~/.config/wofi/

# Copy Mako
echo "🔔 Installing Mako config..."
cp "$CONFIG_DIR/mako/config" ~/.config/mako/

# Copy Yazi theme
echo "📂 Installing Yazi theme..."
cp "$CONFIG_DIR/yazi/theme.toml" ~/.config/yazi/

# Copy Cava config
echo "🎵 Installing Cava config..."
cp "$CONFIG_DIR/cava/config" ~/.config/cava/

# Copy Fastfetch config
echo "💻 Installing Fastfetch config..."
cp "$CONFIG_DIR/fastfetch/config.jsonc" ~/.config/fastfetch/

# Copy toggle script
echo "🔄 Installing mode toggle script..."
cp "$CONFIG_DIR/scripts/toggle-mode" ~/.local/bin/
chmod +x ~/.local/bin/toggle-mode

# Create Screenshots directory
mkdir -p ~/Pictures/Screenshots

echo ""
echo "✅ Midnight Ember rice installed!"
echo ""
echo "Next steps:"
echo "  1. Log out and log back in (or reload Niri: Super+Ctrl+R)"
echo "  2. Test the launcher: Super+Space"
echo "  3. Toggle modes: Super+Shift+V"
echo "  4. Try TUI apps:"
echo "     - Super+E      → Yazi"
echo "     - Super+Shift+C → Cava"
echo "     - Super+Shift+P → ncspot"
echo ""
echo "Theme: Midnight Ember 🔥"
