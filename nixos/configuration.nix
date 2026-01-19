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

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

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

  # Enable Niri (Wayland compositor)
  programs.niri.enable = true;

  # Enable DankMaterialShell (DMS) desktop environment
  programs.dms-shell.enable = true;

  # Enable greetd with tuigreet (minimal TUI greeter - Midnight Ember theme)
  services.xserver.enable = true;
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --time-format '%Y-%m-%d %H:%M' --cmd niri-session --theme 'border=orange;text=white;prompt=orange;time=gray;action=cyan;button=darkgray;container=black;input=white'";
        user = "greeter";
      };
    };
  };

  # Suppress greetd errors on TTY1
  systemd.services.greetd.serviceConfig = {
    Type = "idle";
    StandardInput = "tty";
    StandardOutput = "tty";
    StandardError = "journal";
    TTYReset = true;
    TTYVHangup = true;
    TTYVTDisallocate = true;
  };

  # Enable XWayland for compatibility
  programs.xwayland.enable = true;

  # Stream Deck support
  programs.streamdeck-ui = {
    enable = true;
    autoStart = true;
  };

  # NVIDIA Configuration
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Environment variables for NVIDIA + Wayland
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    WLR_NO_HARDWARE_CURSORS = "1";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    LIBVA_DRIVER_NAME = "nvidia";
  };

  # Configure keymap
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents
  services.printing.enable = true;

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
  security.pam.services.sudo.u2fAuth = true;
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
    tor-browser

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
    timeshift
    fontconfig

    # Wayland tools
    wofi
    fuzzel              # Fast Wayland launcher (alternative to wofi)
    waybar
    wl-clipboard-x11
    swaylock
    swayidle            # Idle management (auto-lock, suspend)
    mako
    libnotify
    xwayland-satellite  # XWayland for legacy X11 apps (Zoho WorkDrive, etc.)
    wlsunset            # Blue light filter for Wayland

    # TUI Tools (Midnight Ember rice)
    yazi
    cava
    fastfetch
    starship
    ncspot
    lazydocker

    # Cursor theme
    bibata-cursors

    # Fonts
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    font-awesome
    material-design-icons
    material-symbols
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    nerd-fonts.meslo-lg

    # Archive management
    xarchiver
    p7zip

    # PDF viewer
    zathura

    # System monitoring
    lm_sensors

    # Network tools
    nmap
    traceroute
    dig

    # KVM/Virtualization support
    qemu
    libvirt
    virt-manager
  ];

  # Enable Fish shell system-wide
  programs.fish.enable = true;

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

  # Enable virtualization (KVM)
  virtualisation.libvirtd.enable = false;  # Disabled - using server for VMs

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
  # Open ports for KDE Connect
  networking.firewall.allowedTCPPortRanges = [ { from = 1714; to = 1764; } ];
  networking.firewall.allowedUDPPortRanges = [ { from = 1714; to = 1764; } ];

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
    package = pkgs.plocate;
  };

  # Home Manager configuration for kaika
  home-manager.users.kaika = { pkgs, config, ... }: {
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
        # Add npm global bin to PATH (for Claude Code)
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

    # Kitty terminal configuration - Midnight Ember theme
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

        # Midnight Ember colors
        background = "#0d1117";
        foreground = "#e6edf3";
        cursor = "#f97316";
        cursor_text_color = "#0d1117";
        selection_background = "#f97316";
        selection_foreground = "#0d1117";

        # Normal colors
        color0 = "#30363d";
        color1 = "#ef4444";
        color2 = "#22c55e";
        color3 = "#eab308";
        color4 = "#22d3ee";
        color5 = "#f5c2e7";
        color6 = "#22d3ee";
        color7 = "#e6edf3";

        # Bright colors
        color8 = "#484f58";
        color9 = "#f87171";
        color10 = "#4ade80";
        color11 = "#facc15";
        color12 = "#67e8f9";
        color13 = "#f5c2e7";
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

    # Starship prompt - Midnight Ember style
    programs.starship = {
      enable = true;
      enableFishIntegration = true;
      settings = {
        format = "$directory$git_branch$git_status$cmd_duration$line_break$character";
        directory = {
          style = "bold cyan";
          truncation_length = 3;
          truncate_to_repo = true;
        };
        git_branch = {
          symbol = " ";
          style = "bold #f97316";
        };
        git_status = {
          style = "bold #f97316";
          staged = "[+$count](green)";
          modified = "[~$count](yellow)";
          untracked = "[?$count](blue)";
        };
        cmd_duration = {
          min_time = 2000;
          style = "bold #30363d";
        };
        character = {
          success_symbol = "[❯](bold #f97316)";
          error_symbol = "[❯](bold red)";
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
        name = "Adwaita";
        package = pkgs.adwaita-icon-theme;
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
      # Midnight Ember CSS overrides
      gtk3.extraCss = ''
        /* Midnight Ember GTK3 Theme */
        @define-color accent_color #f97316;
        @define-color accent_bg_color #f97316;
        @define-color accent_fg_color #0d1117;
        @define-color window_bg_color rgba(13, 17, 23, 0.92);
        @define-color window_fg_color #e6edf3;
        @define-color view_bg_color rgba(10, 14, 20, 0.92);
        @define-color view_fg_color #e6edf3;
        @define-color headerbar_bg_color rgba(10, 14, 20, 0.95);
        @define-color headerbar_fg_color #e6edf3;
        @define-color card_bg_color rgba(22, 27, 34, 0.9);
        @define-color card_fg_color #e6edf3;
        @define-color popover_bg_color rgba(22, 27, 34, 0.95);
        @define-color popover_fg_color #e6edf3;
        @define-color sidebar_bg_color rgba(10, 14, 20, 0.92);
        @define-color sidebar_fg_color #e6edf3;

        window, .background {
          background-color: rgba(13, 17, 23, 0.92);
        }

        headerbar, .titlebar {
          background-color: rgba(10, 14, 20, 0.95);
          border-bottom: 1px solid #30363d;
        }

        .sidebar, .navigation-sidebar {
          background-color: rgba(10, 14, 20, 0.92);
        }

        button:checked, button.suggested-action {
          background-color: #f97316;
          color: #0d1117;
        }

        button:checked:hover, button.suggested-action:hover {
          background-color: #fb923c;
        }

        selection, *:selected {
          background-color: rgba(249, 115, 22, 0.4);
        }

        row:selected, treeview:selected {
          background-color: rgba(249, 115, 22, 0.3);
        }

        check:checked, radio:checked {
          background-color: #f97316;
          color: #0d1117;
        }

        progressbar progress {
          background-color: #f97316;
        }

        scale highlight {
          background-color: #f97316;
        }

        switch:checked slider {
          background-color: #f97316;
        }

        entry:focus, treeview:focus, textview:focus {
          border-color: #f97316;
          box-shadow: 0 0 0 1px #f97316;
        }

        scrollbar slider {
          background-color: #484f58;
        }

        scrollbar slider:hover {
          background-color: #f97316;
        }
      '';
      gtk4.extraCss = ''
        /* Midnight Ember GTK4 Theme */
        @define-color accent_color #f97316;
        @define-color accent_bg_color #f97316;
        @define-color accent_fg_color #0d1117;
        @define-color window_bg_color rgba(13, 17, 23, 0.92);
        @define-color window_fg_color #e6edf3;
        @define-color view_bg_color rgba(10, 14, 20, 0.92);
        @define-color view_fg_color #e6edf3;
        @define-color headerbar_bg_color rgba(10, 14, 20, 0.95);
        @define-color headerbar_fg_color #e6edf3;
        @define-color card_bg_color rgba(22, 27, 34, 0.9);
        @define-color card_fg_color #e6edf3;
        @define-color popover_bg_color rgba(22, 27, 34, 0.95);
        @define-color popover_fg_color #e6edf3;
        @define-color sidebar_bg_color rgba(10, 14, 20, 0.92);
        @define-color sidebar_fg_color #e6edf3;

        window, .background {
          background-color: rgba(13, 17, 23, 0.92);
        }

        headerbar, .titlebar {
          background-color: rgba(10, 14, 20, 0.95);
          border-bottom: 1px solid #30363d;
        }

        .sidebar-pane, .navigation-sidebar {
          background-color: rgba(10, 14, 20, 0.92);
        }

        button:checked, button.suggested-action {
          background-color: #f97316;
          color: #0d1117;
        }

        selection, *:selected {
          background-color: rgba(249, 115, 22, 0.4);
        }

        row:selected {
          background-color: rgba(249, 115, 22, 0.3);
        }

        check:checked, radio:checked {
          background-color: #f97316;
        }

        progressbar > trough > progress {
          background-color: #f97316;
        }

        scale > trough > highlight {
          background-color: #f97316;
        }

        entry:focus-within {
          outline-color: #f97316;
        }

        scrollbar > range > trough > slider {
          background-color: #484f58;
        }

        scrollbar > range > trough > slider:hover {
          background-color: #f97316;
        }
      '';
    };

    # Qt dark theme
    qt = {
      enable = true;
      platformTheme.name = "adwaita";
      style.name = "adwaita-dark";
    };

    # VSCode configuration - Midnight Ember theme
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
        # Midnight Ember color overrides
        "workbench.colorTheme" = "Default Dark Modern";
        "workbench.colorCustomizations" = {
          # Background colors with transparency feel
          "editor.background" = "#0d1117";
          "sideBar.background" = "#0a0e14";
          "sideBarSectionHeader.background" = "#0d1117";
          "activityBar.background" = "#0a0e14";
          "panel.background" = "#0a0e14";
          "terminal.background" = "#0d1117";
          "titleBar.activeBackground" = "#0a0e14";
          "titleBar.inactiveBackground" = "#0a0e14";
          "tab.activeBackground" = "#0d1117";
          "tab.inactiveBackground" = "#0a0e14";
          "editorGroupHeader.tabsBackground" = "#0a0e14";
          "statusBar.background" = "#0a0e14";
          "statusBar.noFolderBackground" = "#0a0e14";
          "statusBar.debuggingBackground" = "#f97316";

          # Orange accent colors
          "activityBarBadge.background" = "#f97316";
          "activityBar.activeBorder" = "#f97316";
          "tab.activeBorder" = "#f97316";
          "focusBorder" = "#f97316";
          "textLink.foreground" = "#f97316";
          "textLink.activeForeground" = "#fb923c";
          "progressBar.background" = "#f97316";
          "editorCursor.foreground" = "#f97316";
          "terminalCursor.foreground" = "#f97316";
          "selection.background" = "#f9731640";
          "editor.selectionBackground" = "#f9731640";
          "editor.selectionHighlightBackground" = "#f9731630";
          "list.activeSelectionBackground" = "#f9731640";
          "list.focusBackground" = "#f9731630";
          "list.highlightForeground" = "#f97316";
          "button.background" = "#f97316";
          "button.hoverBackground" = "#fb923c";

          # Borders
          "sideBar.border" = "#30363d";
          "panel.border" = "#30363d";
          "editorGroup.border" = "#30363d";
          "tab.border" = "#30363d";
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
      BROWSER = "brave";
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
  };

  system.stateVersion = "24.11";
}
