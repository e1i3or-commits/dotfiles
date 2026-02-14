# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').

{ config, pkgs, inputs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Frost Peak GDM Theme - patch gnome-shell's theme gresource with custom colors
  # Note: This causes gnome-shell to build from source (~5 min on Ryzen 9 7900X)
  nixpkgs.overlays = [(final: prev: {
    gnome-shell = prev.gnome-shell.overrideAttrs (old: {
      nativeBuildInputs = (old.nativeBuildInputs or []) ++ [ final.glib.dev ];
      postInstall = (old.postInstall or "") + ''
        echo "Patching gnome-shell theme with Frost Peak colors..."
        GRESOURCE=$out/share/gnome-shell/gnome-shell-theme.gresource
        WRKDIR=$(pwd)/frost-peak-tmp
        mkdir -p $WRKDIR

        for res in $(gresource list $GRESOURCE); do
          mkdir -p "$WRKDIR/$(dirname "$res")"
          gresource extract $GRESOURCE "$res" > "$WRKDIR/$res"
        done

        cat ${./gdm-theme/frost-peak-overrides.css} >> $WRKDIR/org/gnome/shell/theme/gnome-shell-dark.css

        cat > $WRKDIR/gnome-shell-theme.gresource.xml << 'XMLEOF'
<?xml version="1.0" encoding="UTF-8"?>
<gresources>
  <gresource prefix="/org/gnome/shell/theme">
    <file>calendar-today-light.svg</file>
    <file>calendar-today.svg</file>
    <file>gnome-shell-dark.css</file>
    <file>gnome-shell-high-contrast.css</file>
    <file>gnome-shell-light.css</file>
    <file>gnome-shell-start.svg</file>
    <file>pad-osd.css</file>
    <file>workspace-placeholder.svg</file>
  </gresource>
</gresources>
XMLEOF

        glib-compile-resources \
          --sourcedir=$WRKDIR/org/gnome/shell/theme \
          --target=$GRESOURCE \
          $WRKDIR/gnome-shell-theme.gresource.xml

        rm -rf $WRKDIR
        echo "Frost Peak GDM theme applied."
      '';
    });
  })];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;  # Keep only 10 generations in boot menu
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 3;  # 3 second boot menu timeout

  # Use Xanmod kernel for better desktop/gaming performance
  boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;

  # Kernel parameters
  boot.kernelParams = [
    "amd_pstate=active"                                # Hardware-managed CPU frequency scaling for Zen 4
    "nowatchdog"                                       # Reduce unnecessary interrupts
    "nmi_watchdog=0"                                   # Disable NMI watchdog (not needed on desktop)
  ];

  # Tmpfs for /tmp - faster builds, less SSD wear
  boot.tmp = {
    useTmpfs = true;
    tmpfsSize = "50%";  # Up to 50% of RAM (16GB with your 32GB)
  };

  # Backup drive mount point (manual unlock required)
  # To use: sudo cryptsetup open /dev/nvme1n1p1 backup-drive && sudo mount /dev/mapper/backup-drive /mnt/backup
  fileSystems."/mnt/backup" = {
    device = "/dev/mapper/backup-drive";
    fsType = "ext4";
    options = [ "nofail" "noauto" ];  # Don't auto-mount, manual only
  };

  # Unmount Zoho WorkDrive FUSE before shutdown
  # The zohoworkdrivets FUSE process can survive SIGKILL during user session teardown,
  # blocking unmount of both /home/kaika/ZohoWorkDrive and /home.
  systemd.services.zoho-unmount = {
    description = "Unmount Zoho WorkDrive before shutdown";
    before = [ "shutdown.target" "reboot.target" "halt.target" "umount.target" ];
    after = [ "network.target" ];
    wantedBy = [ "shutdown.target" "reboot.target" "halt.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.procps}/bin/pkill -TERM zohoworkdrivets 2>/dev/null; sleep 2; ${pkgs.procps}/bin/pkill -9 zohoworkdrivets 2>/dev/null; sleep 1; ${pkgs.util-linux}/bin/fusermount -uz /home/kaika/ZohoWorkDrive 2>/dev/null; exit 0'";
      TimeoutStartSec = "15s";
    };
  };

  # Hostname
  networking.hostName = "nixos";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone
  time.timeZone = "America/New_York";

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

  # GSettings/dconf support (needed by GTK/Tauri apps like Maestro)
  programs.dconf.enable = true;

  # Enable Niri (Wayland compositor)
  programs.niri.enable = true;

  # DMS disabled - not currently used
  # programs.dms-shell.enable = true;

  # Waybar - stable status bar for Wayland
  programs.waybar.enable = true;

  # Enable GDM (GNOME Display Manager) with Wayland
  services.xserver.enable = true;
  services.displayManager.gdm = {
    enable = true;
    wayland = true;
    banner = "Welcome";
  };

  # GDM Frost Peak greeter settings
  environment.etc."gdm/greeter.dconf-defaults".text = ''
    [org/gnome/desktop/background]
    picture-uri='file:///etc/gdm/wallpaper.jpg'
    picture-uri-dark='file:///etc/gdm/wallpaper.jpg'
    picture-options='zoom'
    primary-color='#0c0e14'

    [org/gnome/desktop/interface]
    color-scheme='prefer-dark'
    accent-color='blue'
    font-name='JetBrainsMono Nerd Font 11'
    cursor-theme='Adwaita'
    enable-animations=true

    [org/gnome/login-screen]
    logo='file:///etc/gdm/frost-peak-logo.svg'
    banner-message-enable=true
    banner-message-text='Welcome to Frost Peak'
  '';

  environment.etc."gdm/frost-peak-logo.svg".source = ./gdm-theme/frost-peak-logo.svg;

  environment.etc."gdm/wallpaper.jpg".source = ./gdm-theme/wallpaper.jpg;

  # GDM monitor layout - main display on DP-2 (ultrawide), vertical on DP-3
  environment.etc."gdm/monitors.xml".text = ''
    <monitors version="2">
      <configuration>
        <logicalmonitor>
          <x>0</x>
          <y>0</y>
          <scale>1</scale>
          <primary>yes</primary>
          <monitor>
            <monitorspec>
              <connector>DP-2</connector>
              <vendor>SAM</vendor>
              <product>LC49G95T</product>
              <serial>HCSW402682</serial>
            </monitorspec>
            <mode>
              <width>5120</width>
              <height>1440</height>
              <rate>119.999</rate>
            </mode>
          </monitor>
        </logicalmonitor>
        <logicalmonitor>
          <x>5120</x>
          <y>0</y>
          <scale>1</scale>
          <transform>
            <rotation>left</rotation>
            <flipped>no</flipped>
          </transform>
          <monitor>
            <monitorspec>
              <connector>DP-3</connector>
              <vendor>SAM</vendor>
              <product>LC34G55T</product>
              <serial>H4ZRA01202</serial>
            </monitorspec>
            <mode>
              <width>3440</width>
              <height>1440</height>
              <rate>99.982</rate>
            </mode>
          </monitor>
        </logicalmonitor>
      </configuration>
    </monitors>
  '';

  # GDM user home must point to /run/gdm so the greeter finds monitors.xml
  users.users.gdm.home = "/run/gdm";

  # Symlink monitors.xml into GDM's config directory
  systemd.tmpfiles.rules = [
    "d /run/gdm/.config 0711 gdm gdm"
    "L+ /run/gdm/.config/monitors.xml - - - - /etc/gdm/monitors.xml"
  ];

  # Enable XWayland for compatibility
  programs.xwayland.enable = true;

  # Stream Deck support
  programs.streamdeck-ui = {
    enable = true;
    autoStart = true;
  };

  # AMD GPU (RX 7900 XT) - uses open-source amdgpu driver + Mesa
  hardware.graphics.enable = true;

  # Environment variables for Wayland
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";      # Wayland with fallback for incompatible apps
    MOZ_ENABLE_WAYLAND = "1";                    # Firefox native Wayland
    # GSettings schemas for GTK/Tauri apps (Maestro, etc.) - merged into one directory
    GSETTINGS_SCHEMA_DIR = let
      schemaDir = pkgs.runCommand "merged-gsettings-schemas" {
        nativeBuildInputs = [ pkgs.glib.dev ];
      } ''
        mkdir -p $out/glib-2.0/schemas
        cp ${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}/glib-2.0/schemas/*.xml $out/glib-2.0/schemas/
        cp ${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}/glib-2.0/schemas/*.xml $out/glib-2.0/schemas/
        glib-compile-schemas $out/glib-2.0/schemas/
      '';
    in "${schemaDir}/glib-2.0/schemas";
  };

  # Configure keymap
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents
  services.printing.enable = true;
  services.printing.drivers = [ pkgs.brlaser ];  # Brother laser printer driver

  # Enable sound with pipewire
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;

  # YubiKey support
  services.udev.packages = [ pkgs.yubikey-personalization ];
  services.pcscd.enable = true;

  # Stream Deck - disable USB autosuspend to prevent disconnects
  services.udev.extraRules = ''
    # Elgato Stream Deck MK.2 - disable autosuspend
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0fd9", ATTR{idProduct}=="0080", ATTR{power/autosuspend}="-1", ATTR{power/control}="on"
    # Elgato Stream Deck (all models)
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0fd9", ATTR{power/autosuspend}="-1", ATTR{power/control}="on"
  '';
  # U2F/YubiKey authentication - plug in key and touch to login/unlock
  security.pam.services.sudo.u2fAuth = true;
  security.pam.services.gdm-password.u2fAuth = true;
  security.pam.services.swaylock.u2fAuth = true;
  security.pam.u2f = {
    enable = true;
    control = "sufficient";  # YubiKey alone is enough, or fall back to password
  };
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Define a user account
  users.users.kaika = {
    isNormalUser = true;
    description = "kaika";
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "docker" ];
    shell = pkgs.fish;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

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
    gh        # GitHub CLI
    vim
    nano
    unzip
    p7zip
    peazip        # GUI archive manager (7-Zip style)
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

    # Browsers (Firefox configured via programs.firefox with PWA support)
    tor-browser
    firefoxpwa      # CLI tool for creating Firefox web apps
    chromium        # For webapps (--app mode)

    # Security/Privacy
    veracrypt
    yubikey-manager
    yubikey-personalization
    pam_u2f

    # Development tools
    vscode
    nodejs_22
    nodePackages.pnpm
    python3
    python3Packages.pip
    lazygit

    # Terminal
    kitty

    # File managers
    thunar
    thunar-volman
    thunar-archive-plugin
    xfconf              # xfconf daemon - needed for Thunar settings persistence
    tumbler             # Thumbnail service for Thunar
    ffmpegthumbnailer   # Video thumbnails

    # Cloud storage
    nextcloud-client

    # Creative & Media
    gimp
    krita
    inkscape
    obs-studio
    vlc
    spotify
    pear-desktop  # YouTube Music client
    imv

    # Productivity
    libreoffice-fresh
    obsidian
    bitwarden-desktop
    kdePackages.kdeconnect-kde

    # System utilities
    pavucontrol
    networkmanagerapplet
    blueman
    grim
    slurp
    wf-recorder   # Lightweight screen recorder for Wayland
    wl-clipboard
    cliphist
    playerctl
    fontconfig
    restic              # Backup tool for home directory

    # Wayland tools
    fuzzel              # Fast Wayland launcher
    waybar
    wl-clipboard-x11
    swaylock
    swayidle            # Idle management (auto-lock, suspend)
    mako
    libnotify
    xwayland-satellite  # XWayland for legacy X11 apps (Zoho WorkDrive, etc.)
    wlsunset            # Blue light filter for Wayland
    swaybg              # Wallpaper tool for Wayland
    hyprpicker          # Wayland color picker

    # TUI Tools (Midnight Ember rice)
    yazi
    cava
    fastfetch
    starship
    ncspot
    lazydocker

    # Cursor theme
    bibata-cursors

    # Note: Fonts are configured in fonts.packages section below

    # Archive management
    xarchiver

    # PDF viewer
    zathura

    # GTK/GSettings support
    gsettings-desktop-schemas

    # System monitoring
    lm_sensors

    # Network tools
    nmap
    traceroute
    dig

  ];

  # Enable Fish shell system-wide
  programs.fish.enable = true;

  # Firefox with PWA support
  programs.firefox = {
    enable = true;
    nativeMessagingHosts.packages = [ pkgs.firefoxpwa ];
  };

  # Chromium for webapps (GPU accelerated)
  programs.chromium = {
    enable = true;
    extraOpts = {
      "HardwareAccelerationModeEnabled" = true;
    };
  };
  environment.sessionVariables.CHROMIUM_FLAGS = "--enable-features=UseOzonePlatform,VaapiVideoEncoder,WebRTCPipeWireCapturer,WebRTCAllowH264Receive,WebRTCAllowH264Send --ozone-platform=wayland --enable-gpu-rasterization --enable-zero-copy --ignore-gpu-blocklist";

  # Enable nix-ld for running prebuilt binaries (Claude Code, Zoho WorkDrive, etc.)
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    zlib
    glib
    glibc
    openssl
    stdenv.cc.cc.lib
    fuse
    fuse3
    libGL
    libxkbcommon
    libx11
    libxext
    libxrender
    libxcb
    libxcb-wm
    libxcb-image
    libxcb-keysyms
    libxcb-render-util
    libxcb-cursor
    libxshmfence
    libxkbfile
    libxcomposite
    libxdamage
    libxfixes
    libxrandr
    libxcursor
    libxi
    libxtst
    libxscrnsaver
    fontconfig
    freetype
    dbus
    libpulseaudio
    alsa-lib
    nss
    nspr
    expat
    cups
    libdrm
    mesa
    wayland
    # Note: Qt6 libraries removed - Zoho WorkDrive bundles its own PyQt6/Qt6
    # and they conflict with system Qt versions
    krb5.lib
    libxcrypt-legacy
  ];

  # FHS compatibility is handled by programs.nix-ld
  # The nix-ld module creates /lib64/ld-linux-x86-64.so.2 symlink automatically

  # Steam gaming
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };
  programs.gamemode.enable = true;  # Optimize system for gaming

  # Fonts configuration
  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      font-awesome
      material-design-icons
      material-symbols
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
  # Open ports for KDE Connect
  networking.firewall.allowedTCPPortRanges = [ { from = 1714; to = 1764; } ];
  networking.firewall.allowedUDPPortRanges = [ { from = 1714; to = 1764; } ];

  # Nix settings for better performance
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];  # Modern nix CLI (flakes optional but useful)
    auto-optimise-store = true;                          # Deduplicate files in store
    max-jobs = "auto";                                   # Parallel builds (auto = num CPUs)
    cores = 0;                                           # Use all cores per derivation (0 = all)
    trusted-users = [ "root" "kaika" ];                  # Allow kaika to use binary caches
  };

  # Automatic garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # Periodic store deduplication (batch, catches anything auto-optimise missed)
  nix.optimise.automatic = true;

  # Space-based automatic GC - triggers when store disk gets low
  nix.extraOptions = ''
    min-free = ${toString (1024 * 1024 * 1024)}
    max-free = ${toString (5 * 1024 * 1024 * 1024)}
  '';

  # Enable SSD TRIM
  services.fstrim.enable = true;

  # ZRAM for better memory management
  zramSwap = {
    enable = true;
    algorithm = "zstd";     # Better compression ratio (~5:1 vs lz4's ~2.5:1), Zen 4 has plenty of CPU
    memoryPercent = 50;     # Use up to 50% of RAM for compressed swap
  };

  # ZRAM + security kernel tuning
  boot.kernel.sysctl = {
    # ZRAM optimization
    "vm.swappiness" = 180;                   # Prefer swapping to ZRAM over dropping file cache (valid >100 with ZRAM)
    "vm.page-cluster" = 0;                   # Disable swap readahead - critical for ZRAM (each page decompressed individually)
    "vm.watermark_boost_factor" = 0;         # Prevent unnecessary page reclaim
    "vm.watermark_scale_factor" = 125;       # Better page reclaim thresholds
    "vm.compaction_proactiveness" = 0;       # Reduce CPU waste on memory compaction

    # Kernel security hardening
    "kernel.kptr_restrict" = 2;              # Hide kernel pointers from all users
    "kernel.yama.ptrace_scope" = 2;          # Restrict ptrace to root only
    "kernel.sysrq" = 0;                      # Disable SysRq magic keys
    "kernel.dmesg_restrict" = 1;             # Restrict dmesg to root
    "kernel.unprivileged_bpf_disabled" = 1;  # Restrict BPF to root
    "net.core.bpf_jit_harden" = 2;           # Harden BPF JIT compiler

    # Network hardening
    "net.ipv4.conf.all.rp_filter" = 1;              # Reverse path filtering
    "net.ipv4.conf.default.rp_filter" = 1;
    "net.ipv4.conf.all.accept_redirects" = 0;       # Reject ICMP redirects
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;         # Don't send ICMP redirects
    "net.ipv4.conf.default.send_redirects" = 0;

    # Filesystem hardening
    "vm.unprivileged_userfaultfd" = 0;       # Restrict userfaultfd to root
    "fs.protected_symlinks" = 1;             # Protect against symlink TOCTOU races
    "fs.protected_hardlinks" = 1;
    "fs.protected_fifos" = 2;
    "fs.protected_regular" = 2;
  };

  # Disable core dumps (prevents sensitive data leaks)
  systemd.coredump.enable = false;

  # Enable locate database
  services.locate = {
    enable = true;
    package = pkgs.plocate;
  };

  system.stateVersion = "24.11";
}
