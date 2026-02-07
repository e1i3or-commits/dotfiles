# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').

{ config, pkgs, inputs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Hostname
  networking.hostName = "nixos"; # Change this to your preferred hostname

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone
  time.timeZone = "America/New_York"; # Change if needed

  # Select internationalisation properties
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable Niri (Wayland compositor)
  # Using nixpkgs version (pre-built, no compilation needed)
  programs.niri = {
    enable = true;
    package = pkgs.niri;  # Use nixpkgs version instead of niri-flake
  };

  # Enable GDM (GNOME Display Manager) with Wayland
  services.xserver.enable = true;
  services.displayManager.gdm = {
    enable = true;
    wayland = true;
  };

  # Enable XWayland for compatibility
  programs.xwayland.enable = true;

  # NVIDIA Configuration
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;  # Use proprietary drivers (more stable)
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Environment variables for NVIDIA + Wayland
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";  # Electron apps on Wayland
    WLR_NO_HARDWARE_CURSORS = "1";  # Fix cursor issues on NVIDIA
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    LIBVA_DRIVER_NAME = "nvidia";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents
  services.printing.enable = true;

  # Enable sound with pipewire
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Enable touchpad support (if needed)
  # services.xserver.libinput.enable = true;

  # Define a user account
  users.users.kaika = {
    isNormalUser = true;
    description = "kaika";
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "docker" ];
    shell = pkgs.fish;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Enable Flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Enable Docker
  virtualisation.docker = {
    enable = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

  # System-wide packages
  environment.systemPackages = with pkgs; [
    # Core utilities
    wget
    curl
    git
    vim
    nano
    unzip
    p7zip
    zip
    tree
    htop
    btop
    file
    which

    # Modern CLI tools
    bat
    eza
    ripgrep
    fd
    zoxide
    fzf
    jq

    # Browsers
    brave

    # Development tools
    vscode
    nodejs_22
    nodePackages.pnpm
    python3
    python3Packages.pip
    lazygit

    # Terminal
    alacritty

    # File managers
    xfce.thunar
    xfce.thunar-volman
    xfce.thunar-archive-plugin

    # Cloud storage
    nextcloud-client
    # Note: Zoho Workdrive may need manual installation - see below

    # Creative & Media
    gimp
    krita
    inkscape
    obs-studio
    vlc
    spotify
    imv # Wayland-native image viewer

    # Productivity
    libreoffice-fresh
    obsidian
    bitwarden-desktop

    # System utilities
    pavucontrol # Audio control
    networkmanagerapplet
    grim # Screenshot tool for Wayland
    slurp # Screen area selection for Wayland
    wl-clipboard # Wayland clipboard utilities
    timeshift

    # Wayland tools
    wofi # Application launcher for Wayland
    waybar # Status bar (optional, if not using DankLinux shell)
    wl-clipboard-x11 # X11 clipboard compatibility

    # Fonts
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    font-awesome
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    nerd-fonts.meslo-lg

    # Archive management
    xarchiver

    # PDF viewer
    zathura

    # System monitoring
    lm_sensors

    # Network tools
    nmap
    traceroute
    dig

    # KVM/Virtualization support (if needed)
    qemu
    libvirt
    virt-manager
  ];

  # Enable Fish shell system-wide
  programs.fish.enable = true;

  # Enable virtualization (KVM)
  virtualisation.libvirtd.enable = true;

  # Fonts configuration
  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      font-awesome
      nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    nerd-fonts.meslo-lg
    ];

    fontconfig = {
      defaultFonts = {
        serif = [ "Noto Serif" ];
        sansSerif = [ "Noto Sans" ];
        monospace = [ "JetBrainsMono Nerd Font" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };

  # Enable firewall
  networking.firewall.enable = true;
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];

  # Enable automatic upgrades (optional - uncomment if desired)
  # system.autoUpgrade = {
  #   enable = true;
  #   allowReboot = false;
  # };

  # Enable automatic garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Enable SSD TRIM
  services.fstrim.enable = true;

  # Enable locate database
  services.locate = {
    enable = true;
    package = pkgs.plocate;  # Modern replacement for mlocate
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}

# NOTES:
#
# 1. ZOHO WORKDRIVE:
#    Zoho Workdrive is not available in nixpkgs. You'll need to install it manually:
#    - Download from: https://www.zoho.com/workdrive/desktop-sync.html
#    - Or use the web interface
#    - Consider using AppImage if available
#
# 2. DANKLINUX INSTALLATION:
#    After system installation, install DankLinux manually:
#    git clone https://github.com/AvengeMedia/DankLinux
#    cd DankLinux
#    ./dankinstall
#
# 3. ENCRYPTED DRIVES:
#    Your hardware-configuration.nix (generated during install) should include:
#    - Encrypted root on nvme0n1
#    - Encrypted /home on nvme1n1
#    - Encrypted backup on nvme2n1
#
# 4. NEXTCLOUD CLIENT SETUP:
#    After installation:
#    - Run: nextcloud
#    - Login to kaika@192.168.88.245:8080
#    - Configure sync folders
#
# 5. SSH KEY FOR NEXTCLOUD SERVER:
#    Your public key for KaapNetBrain server access:
#    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINoNQBJjlZqmIASKV3LbrsiexBYdAyQzTVCowFeCpUdg kaika@nixos
#
# 6. FIRST BUILD:
#    After installation, copy all config files to /etc/nixos/ and run:
#    sudo nixos-rebuild switch --flake /etc/nixos#nixos
#
# 7. CUSTOMIZATION:
#    - Change hostname at line 17
#    - Change timezone at line 23
#    - Add/remove packages as needed
