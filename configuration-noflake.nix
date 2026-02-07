# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      <home-manager/nixos>
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
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
    "nvidia.NVreg_EnableGpuFirmware=1"                 # Explicitly enable GSP firmware (default for open module)
    "nvidia.NVreg_DynamicPowerManagement=0"            # Disable NVIDIA runtime PM - driver 580 defaults to 3, causing P-state oscillations
    "pcie_aspm=off"                                    # Disable PCIe power management - prevents multi-second GPU stalls
    "amd_pstate=active"                                # Hardware-managed CPU frequency scaling for Zen 4
    "nowatchdog"                                       # Reduce unnecessary interrupts
    "nmi_watchdog=0"                                   # Disable NMI watchdog (not needed on desktop)
  ];

  # Prevent nova_core from binding to NVIDIA GPU before proprietary driver (kernel 6.18+)
  boot.blacklistedKernelModules = [ "nova_core" ];

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

  # DMS disabled - causes gray screen refresh issues with NVIDIA + Wayland
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

  environment.etc."gdm/wallpaper.jpg".source = /home/kaika/Pictures/Wallpapers/aishot-769.jpg;

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

  # NVIDIA Configuration
  hardware.graphics.enable = true;
  hardware.graphics.extraPackages = with pkgs; [
    nvidia-vaapi-driver  # Hardware video acceleration
    libva-vdpau-driver   # VA-API to VDPAU translation layer
  ];
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;   # Enable suspend/resume VRAM save (works with PreserveVideoMemoryAllocations)
    powerManagement.finegrained = false;
    open = true;  # Open kernel module (recommended for RTX 40-series / Ada Lovelace)
    nvidiaSettings = true;
    nvidiaPersistenced = true;  # Keep GPU state persistent to prevent micro-freezes
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Prevent GPU from entering deep idle states while driving high-refresh displays
  # Locks minimum GPU clock at 500MHz and disables PCIe D3cold power state
  systemd.services.nvidia-gpu-clocks = {
    description = "Lock NVIDIA GPU minimum clocks for desktop compositing";
    after = [ "nvidia-persistenced.service" ];
    requires = [ "nvidia-persistenced.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "nvidia-gpu-clocks-start" ''
        # Lock GPU clocks: minimum 500MHz (prevents P8 idle dropping to 210MHz)
        ${config.hardware.nvidia.package.bin}/bin/nvidia-smi --lock-gpu-clocks=500,3120 || true
        # Lock memory clocks: prevents wild 810MHz<->10501MHz oscillations at idle
        ${config.hardware.nvidia.package.bin}/bin/nvidia-smi --lock-memory-clocks=810,10501 || true
        # Disable D3cold - prevents deepest PCIe power state on active GPU
        echo 0 > /sys/bus/pci/devices/0000:01:00.0/d3cold_allowed || true
        # Force PCIe runtime PM to "on" (always active)
        echo on > /sys/bus/pci/devices/0000:01:00.0/power/control || true
      '';
      ExecStop = pkgs.writeShellScript "nvidia-gpu-clocks-stop" ''
        ${config.hardware.nvidia.package.bin}/bin/nvidia-smi --reset-gpu-clocks || true
        ${config.hardware.nvidia.package.bin}/bin/nvidia-smi --reset-memory-clocks || true
      '';
    };
  };

  # NVIDIA application profile for Niri - fixes VRAM management
  environment.etc."nvidia/nvidia-application-profiles-rc.d/50-niri-buffer.json".text = ''
    {
      "rules": [{
        "pattern": {"feature": "procname", "matches": "niri"},
        "profile": "Limit Free Buffer Pool On Wayland Compositors"
      }],
      "profiles": [{
        "name": "Limit Free Buffer Pool On Wayland Compositors",
        "settings": [{"key": "GLVidHeapReuseRatio", "value": 0}]
      }]
    }
  '';

  # Environment variables for NVIDIA + Wayland
  # Note: GBM_BACKEND, __GLX_VENDOR_LIBRARY_NAME, DRI_PRIME removed - auto-detected on desktop with NVIDIA primary
  # Note: MOZ_WEBRENDER removed - default in modern Firefox
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    LIBVA_DRIVER_NAME = "nvidia";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";      # Wayland with fallback for incompatible apps
    MOZ_ENABLE_WAYLAND = "1";                    # Firefox native Wayland
    MOZ_DRM_DEVICE = "/dev/dri/renderD128";      # Use NVIDIA GPU for Firefox
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

  # Home Manager settings
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "backup";

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
    (btop.override { cudaSupport = true; })
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
    xfce.tumbler        # Thumbnail service for Thunar
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
  environment.sessionVariables.CHROMIUM_FLAGS = "--enable-features=UseOzonePlatform,VaapiVideoDecoder,VaapiVideoEncoder --ozone-platform=wayland --enable-gpu-rasterization --enable-zero-copy --ignore-gpu-blocklist";

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
    xorg.libX11
    xorg.libXext
    xorg.libXrender
    xorg.libxcb
    xorg.xcbutilwm
    xorg.xcbutilimage
    xorg.xcbutilkeysyms
    xorg.xcbutilrenderutil
    xorg.xcbutilcursor
    xorg.libxshmfence
    xorg.libxkbfile
    xorg.libXcomposite
    xorg.libXdamage
    xorg.libXfixes
    xorg.libXrandr
    xorg.libXcursor
    xorg.libXi
    xorg.libXtst
    xorg.libXScrnSaver
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

  # Home Manager configuration for kaika
  home-manager.users.kaika = { pkgs, config, lib, ... }: {
    home.stateVersion = "24.11";
    home.enableNixpkgsReleaseCheck = false;  # Allow version mismatch

    home.packages = with pkgs; [];

    # Git configuration
    programs.git = {
      enable = true;
      settings = {
        user.name = "kaika";
        user.email = "kaikaapro@gmail.com";
        init.defaultBranch = "main";
        pull.rebase = false;
      };
    };

    # Fish shell configuration
    programs.fish = {
      enable = true;
      shellAbbrs = {
        g = "git";
        ga = "git add";
        gc = "git commit";
        gp = "git push";
        gs = "git status";
        gd = "git diff";
        gl = "git log";
        nrs = "sudo nixos-rebuild switch";
        nrt = "sudo nixos-rebuild test";
        cat = "bat";
        ls = "eza";
        ll = "eza -l";
        la = "eza -la";
        tree = "eza --tree";
      };
      shellAliases = {
        cd = "z";
      };
      interactiveShellInit = ''
        # Starship prompt (handled by programs.starship)
        set fish_greeting ""
        # Add custom scripts and npm global to PATH
        fish_add_path ~/.local/bin
        fish_add_path ~/.npm-global/bin
        # Midnight Ember fish colors
        set -g fish_color_autosuggestion 484f58
        set -g fish_color_command 22c55e
        set -g fish_color_param e6edf3
        set -g fish_color_error ef4444
        set -g fish_color_quote eab308
        set -g fish_color_operator 22d3ee
        # Show fastfetch on new terminal
        if status is-interactive
          fastfetch
        end
      '';
    };

    # Thunar - default to list view (must be a real writable file, not a symlink)
    home.activation.thunarConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      thunarrc="$HOME/.config/Thunar/thunarrc"
      mkdir -p "$(dirname "$thunarrc")"
      if [ ! -f "$thunarrc" ] || [ -L "$thunarrc" ]; then
        rm -f "$thunarrc"
        cat > "$thunarrc" << 'EOF'
[Configuration]
DefaultView=ThunarDetailsView
LastView=ThunarDetailsView
EOF
      fi
    '';

    # Kitty terminal configuration - Frost Peak theme
    programs.kitty = {
      enable = true;
      settings = {
        # Window
        background_opacity = "0.92";
        window_padding_width = 12;
        confirm_os_window_close = 0;

        # Font
        font_family = "JetBrainsMono Nerd Font";
        bold_font = "JetBrainsMono Nerd Font Bold";
        italic_font = "JetBrainsMono Nerd Font Italic";
        font_size = 12;

        # Frost Peak colors
        background = "#0c0e14";
        foreground = "#e0e6f0";
        cursor = "#38bdf8";
        cursor_text_color = "#0c0e14";
        selection_background = "#1e3a5f";
        selection_foreground = "none";

        # Normal colors
        color0 = "#262a3a";
        color1 = "#f87171";
        color2 = "#34d399";
        color3 = "#f59e0b";
        color4 = "#38bdf8";
        color5 = "#a78bfa";
        color6 = "#22d3ee";
        color7 = "#e0e6f0";

        # Bright colors
        color8 = "#3a3f52";
        color9 = "#fca5a5";
        color10 = "#6ee7b7";
        color11 = "#fbbf24";
        color12 = "#7dd3fc";
        color13 = "#c4b5fd";
        color14 = "#67e8f9";
        color15 = "#ffffff";

        # Cursor
        cursor_shape = "block";
        cursor_blink_interval = 0;

        # Shell integration
        shell_integration = "enabled";
      };
    };

    # Bat configuration
    programs.bat = {
      enable = true;
      config = { theme = "TwoDark"; paging = "auto"; };
    };

    # Zoxide configuration
    programs.zoxide = {
      enable = true;
      enableFishIntegration = true;
    };

    # fzf configuration
    programs.fzf = {
      enable = true;
      enableFishIntegration = true;
    };

    # Starship prompt - Frost Peak style
    programs.starship = {
      enable = true;
      enableFishIntegration = true;
      settings = {
        format = "$directory$git_branch$git_status$cmd_duration$line_break$character";
        directory = {
          style = "bold #22d3ee";
          truncation_length = 3;
          truncate_to_repo = true;
        };
        git_branch = {
          symbol = " ";
          style = "bold #a78bfa";
        };
        git_status = {
          style = "bold #a78bfa";
          staged = "[+$count](bold #34d399)";
          modified = "[~$count](bold #f59e0b)";
          untracked = "[?$count](bold #38bdf8)";
        };
        cmd_duration = {
          min_time = 2000;
          style = "bold #3a3f52";
        };
        character = {
          success_symbol = "[❯](bold #38bdf8)";
          error_symbol = "[❯](bold #f87171)";
        };
      };
    };

    # GTK dark theme - Midnight Ember
    gtk = {
      enable = true;
      theme = {
        name = "Adwaita-dark";
        package = pkgs.gnome-themes-extra;
      };
      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };
      cursorTheme = {
        name = "Bibata-Modern-Ice";
        package = pkgs.bibata-cursors;
        size = 24;
      };
      gtk3.extraConfig = {
        gtk-application-prefer-dark-theme = true;
      };
      gtk4.extraConfig = {
        gtk-application-prefer-dark-theme = true;
      };
      # Frost Peak CSS overrides
      gtk3.extraCss = ''
        /* Frost Peak GTK3 Theme */
        @define-color accent_color #38bdf8;
        @define-color accent_bg_color #38bdf8;
        @define-color accent_fg_color #06080c;
        @define-color window_bg_color rgba(12, 14, 20, 0.92);
        @define-color window_fg_color #e0e6f0;
        @define-color view_bg_color rgba(6, 8, 12, 0.92);
        @define-color view_fg_color #e0e6f0;
        @define-color headerbar_bg_color rgba(6, 8, 12, 0.95);
        @define-color headerbar_fg_color #e0e6f0;
        @define-color card_bg_color rgba(20, 22, 32, 0.9);
        @define-color card_fg_color #e0e6f0;
        @define-color popover_bg_color rgba(20, 22, 32, 0.95);
        @define-color popover_fg_color #e0e6f0;
        @define-color sidebar_bg_color rgba(6, 8, 12, 0.92);
        @define-color sidebar_fg_color #e0e6f0;

        window, .background {
          background-color: rgba(12, 14, 20, 0.92);
        }

        headerbar, .titlebar {
          background-color: rgba(6, 8, 12, 0.95);
          border-bottom: 1px solid #262a3a;
        }

        .sidebar, .navigation-sidebar {
          background-color: rgba(6, 8, 12, 0.92);
        }

        /* Ensure all content views are transparent (Thunar, Nautilus, etc.) */
        .view, treeview, iconview, textview text, list, placessidebar, placesview {
          background-color: rgba(6, 8, 12, 0.92);
        }

        treeview header button {
          background-color: rgba(6, 8, 12, 0.95);
          border-color: #262a3a;
        }

        toolbar, .toolbar, .path-bar, .linked button {
          background-color: rgba(12, 14, 20, 0.92);
        }

        statusbar, .statusbar {
          background-color: rgba(6, 8, 12, 0.92);
        }

        paned separator {
          background-color: #262a3a;
        }

        button:checked, button.suggested-action {
          background-color: #38bdf8;
          color: #06080c;
        }

        button:checked:hover, button.suggested-action:hover {
          background-color: #7dd3fc;
        }

        selection, *:selected {
          background-color: rgba(56, 189, 248, 0.35);
        }

        row:selected, treeview:selected {
          background-color: rgba(56, 189, 248, 0.25);
        }

        check:checked, radio:checked {
          background-color: #38bdf8;
          color: #06080c;
        }

        progressbar progress {
          background-color: #38bdf8;
        }

        scale highlight {
          background-color: #38bdf8;
        }

        switch:checked slider {
          background-color: #38bdf8;
        }

        entry:focus, treeview:focus, textview:focus {
          border-color: #38bdf8;
          box-shadow: 0 0 0 1px #38bdf8;
        }

        scrollbar slider {
          background-color: #3a3f52;
        }

        scrollbar slider:hover {
          background-color: #38bdf8;
        }
      '';
      gtk4.extraCss = ''
        /* Frost Peak GTK4 Theme */
        @define-color accent_color #38bdf8;
        @define-color accent_bg_color #38bdf8;
        @define-color accent_fg_color #06080c;
        @define-color window_bg_color rgba(12, 14, 20, 0.92);
        @define-color window_fg_color #e0e6f0;
        @define-color view_bg_color rgba(6, 8, 12, 0.92);
        @define-color view_fg_color #e0e6f0;
        @define-color headerbar_bg_color rgba(6, 8, 12, 0.95);
        @define-color headerbar_fg_color #e0e6f0;
        @define-color card_bg_color rgba(20, 22, 32, 0.9);
        @define-color card_fg_color #e0e6f0;
        @define-color popover_bg_color rgba(20, 22, 32, 0.95);
        @define-color popover_fg_color #e0e6f0;
        @define-color sidebar_bg_color rgba(6, 8, 12, 0.92);
        @define-color sidebar_fg_color #e0e6f0;

        window, .background {
          background-color: rgba(12, 14, 20, 0.92);
        }

        headerbar, .titlebar {
          background-color: rgba(6, 8, 12, 0.95);
          border-bottom: 1px solid #262a3a;
        }

        .sidebar-pane, .navigation-sidebar {
          background-color: rgba(6, 8, 12, 0.92);
        }

        listview, columnview, gridview, textview text {
          background-color: rgba(6, 8, 12, 0.92);
        }

        separator {
          background-color: #262a3a;
        }

        statusbar, actionbar {
          background-color: rgba(6, 8, 12, 0.92);
        }

        button:checked, button.suggested-action {
          background-color: #38bdf8;
          color: #06080c;
        }

        selection, *:selected {
          background-color: rgba(56, 189, 248, 0.35);
        }

        row:selected {
          background-color: rgba(56, 189, 248, 0.25);
        }

        check:checked, radio:checked {
          background-color: #38bdf8;
        }

        progressbar > trough > progress {
          background-color: #38bdf8;
        }

        scale > trough > highlight {
          background-color: #38bdf8;
        }

        entry:focus-within {
          outline-color: #38bdf8;
        }

        scrollbar > range > trough > slider {
          background-color: #3a3f52;
        }

        scrollbar > range > trough > slider:hover {
          background-color: #38bdf8;
        }
      '';
    };

    # Qt dark theme
    qt = {
      enable = true;
      platformTheme.name = "adwaita";
      style.name = "adwaita-dark";
    };

    # VSCode configuration - Frost Peak theme
    programs.vscode = {
      enable = true;
      profiles.default.extensions = with pkgs.vscode-extensions; [
        ms-python.python
        ms-vscode.cpptools
        bbenoist.nix
        eamodio.gitlens
        pkief.material-icon-theme
        esbenp.prettier-vscode
        dbaeumer.vscode-eslint
      ];
      profiles.default.userSettings = {
        # Frost Peak color overrides
        "workbench.colorTheme" = "Default Dark Modern";
        "workbench.colorCustomizations" = {
          # Background colors - deep void blacks
          "editor.background" = "#0c0e14";
          "sideBar.background" = "#06080c";
          "sideBarSectionHeader.background" = "#0c0e14";
          "activityBar.background" = "#06080c";
          "panel.background" = "#06080c";
          "terminal.background" = "#0c0e14";
          "titleBar.activeBackground" = "#06080c";
          "titleBar.inactiveBackground" = "#06080c";
          "tab.activeBackground" = "#0c0e14";
          "tab.inactiveBackground" = "#06080c";
          "editorGroupHeader.tabsBackground" = "#06080c";
          "statusBar.background" = "#06080c";
          "statusBar.noFolderBackground" = "#06080c";
          "statusBar.debuggingBackground" = "#a78bfa";

          # Ice blue accent colors
          "activityBarBadge.background" = "#38bdf8";
          "activityBar.activeBorder" = "#38bdf8";
          "tab.activeBorder" = "#38bdf8";
          "focusBorder" = "#38bdf8";
          "textLink.foreground" = "#38bdf8";
          "textLink.activeForeground" = "#7dd3fc";
          "progressBar.background" = "#38bdf8";
          "editorCursor.foreground" = "#38bdf8";
          "terminalCursor.foreground" = "#38bdf8";
          "selection.background" = "#38bdf835";
          "editor.selectionBackground" = "#38bdf835";
          "editor.selectionHighlightBackground" = "#38bdf825";
          "list.activeSelectionBackground" = "#38bdf835";
          "list.focusBackground" = "#38bdf825";
          "list.highlightForeground" = "#38bdf8";
          "button.background" = "#38bdf8";
          "button.foreground" = "#06080c";
          "button.hoverBackground" = "#7dd3fc";

          # Violet secondary accents
          "editorLineNumber.activeForeground" = "#a78bfa";
          "editorBracketHighlight.foreground1" = "#38bdf8";
          "editorBracketHighlight.foreground2" = "#a78bfa";
          "editorBracketHighlight.foreground3" = "#f59e0b";
          "gitDecoration.modifiedResourceForeground" = "#f59e0b";
          "gitDecoration.untrackedResourceForeground" = "#34d399";
          "gitDecoration.deletedResourceForeground" = "#f87171";

          # Borders
          "sideBar.border" = "#262a3a";
          "panel.border" = "#262a3a";
          "editorGroup.border" = "#262a3a";
          "tab.border" = "#262a3a";
        };

        # Editor token color customizations
        "editor.tokenColorCustomizations" = {
          "comments" = "#3a3f52";
          "strings" = "#34d399";
          "keywords" = "#a78bfa";
          "numbers" = "#f59e0b";
          "functions" = "#38bdf8";
          "variables" = "#e0e6f0";
          "types" = "#22d3ee";
        };

        # Editor settings
        "editor.fontFamily" = "'JetBrainsMono Nerd Font', 'Droid Sans Mono', monospace";
        "editor.fontSize" = 14;
        "editor.fontLigatures" = true;
        "editor.cursorBlinking" = "solid";
        "editor.cursorStyle" = "block";
        "editor.minimap.enabled" = false;
        "editor.renderWhitespace" = "selection";
        "editor.bracketPairColorization.enabled" = true;

        # Terminal
        "terminal.integrated.fontFamily" = "'JetBrainsMono Nerd Font'";
        "terminal.integrated.fontSize" = 12;

        # Window
        "window.titleBarStyle" = "custom";
        "window.menuBarVisibility" = "toggle";

        # File icons
        "workbench.iconTheme" = "material-icon-theme";
      };
    };

    # Environment variables
    home.sessionVariables = {
      EDITOR = "code";
      VISUAL = "code";
      TERMINAL = "kitty";
      BROWSER = "firefox";
    };

    # XDG user directories
    xdg.enable = true;
    xdg.userDirs = {
      enable = true;
      createDirectories = true;
      desktop = "${config.home.homeDirectory}/Desktop";
      documents = "${config.home.homeDirectory}/Documents";
      download = "${config.home.homeDirectory}/Downloads";
      music = "${config.home.homeDirectory}/Music";
      pictures = "${config.home.homeDirectory}/Pictures";
      videos = "${config.home.homeDirectory}/Videos";
      templates = "${config.home.homeDirectory}/Templates";
      publicShare = "${config.home.homeDirectory}/Public";
    };

    # Set Firefox as default browser
    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "text/html" = "firefox.desktop";
        "x-scheme-handler/http" = "firefox.desktop";
        "x-scheme-handler/https" = "firefox.desktop";
        "x-scheme-handler/about" = "firefox.desktop";
        "x-scheme-handler/unknown" = "firefox.desktop";
      };
    };
  };

  system.stateVersion = "24.11";
}
