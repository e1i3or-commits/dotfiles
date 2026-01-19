#!/usr/bin/env bash
# Dotfiles installer - creates symlinks from repo to home

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing dotfiles from: $DOTFILES_DIR"
echo ""

# Create necessary directories
mkdir -p ~/.config
mkdir -p ~/.local/bin

# Function to create symlink with backup
link_config() {
    local src="$DOTFILES_DIR/config/$1"
    local dest="$HOME/.config/$1"

    if [ -e "$src" ]; then
        if [ -L "$dest" ]; then
            rm "$dest"
        elif [ -e "$dest" ]; then
            echo "  Backing up existing $dest to $dest.backup"
            mv "$dest" "$dest.backup"
        fi
        ln -sf "$src" "$dest"
        echo "  Linked: ~/.config/$1"
    fi
}

# Function to link scripts
link_script() {
    local src="$DOTFILES_DIR/local/bin/$1"
    local dest="$HOME/.local/bin/$1"

    if [ -e "$src" ]; then
        if [ -L "$dest" ]; then
            rm "$dest"
        elif [ -e "$dest" ]; then
            mv "$dest" "$dest.backup"
        fi
        ln -sf "$src" "$dest"
        chmod +x "$dest"
        echo "  Linked: ~/.local/bin/$1"
    fi
}

echo "Linking config files..."
link_config "niri"
link_config "alacritty"
link_config "fish"
link_config "fuzzel"
link_config "waybar"
link_config "mako"
link_config "swaylock"
link_config "swayidle"
link_config "btop"
link_config "cava"
link_config "fastfetch"
link_config "yazi"
link_config "starship.toml"

echo ""
echo "Linking scripts..."
link_script "night-mode"
link_script "screenrecord"
link_script "toggle-mode"
link_script "webapp-install"
link_script "webapp-remove"
link_script "webapp-list"

echo ""
echo "Done! Dotfiles installed."
echo ""
echo "Note: NixOS config is in nixos/ - copy manually:"
echo "  sudo cp $DOTFILES_DIR/nixos/configuration.nix /etc/nixos/configuration.nix"
