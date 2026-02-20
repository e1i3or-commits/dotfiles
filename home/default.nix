# Home Manager configuration for kaika
# Extracted from the monolithic configuration-noflake.nix
# Programs here generate Nix-managed configs (kitty, starship, fish, etc.)
# Dotfiles in config/ are symlinked directly via mkOutOfStoreSymlink (live-editable)

{ config, pkgs, lib, inputs, ... }:

let
  # Absolute path to the nix-config repo (~/nix-config symlink)
  # Used by mkOutOfStoreSymlink to create direct symlinks to repo files
  dotfilesPath = "/home/kaika/nix-config";
in
{
  imports = [
    inputs.noctalia.homeModules.default
  ];

  home.stateVersion = "24.11";
  home.enableNixpkgsReleaseCheck = false;

  home.packages = with pkgs; [];

  # ===========================================================================
  # NOCTALIA SHELL - Frost Peak theme
  # ===========================================================================

  programs.noctalia-shell = {
    enable = true;

    settings = {
      bar = {
        position = "top";
        monitors = ["DP-3"];
        density = "compact";
        showCapsule = true;
        capsuleOpacity = 0.85;
        backgroundOpacity = 0.7;
        floating = true;
        marginVertical = 4;
        marginHorizontal = 6;
        outerCorners = true;
        exclusive = true;
        widgets = {
          left = [
            {
              id = "Launcher";
              useDistroLogo = true;
            }
            {
              id = "Workspace";
              hideUnoccupied = true;
              labelMode = "none";
            }
            {
              id = "ActiveWindow";
            }
          ];
          center = [
            {
              id = "Clock";
              formatHorizontal = "ddd MMM d  h:mm a";
              useMonospacedFont = true;
              usePrimaryColor = true;
            }
          ];
          right = [
            {
              id = "MediaMini";
            }
            {
              id = "SystemMonitor";
            }
            {
              id = "Tray";
            }
            {
              id = "Volume";
            }
            {
              id = "NotificationHistory";
            }
            {
              id = "ControlCenter";
            }
          ];
        };
      };
      general = {
        animationSpeed = 1.5;
        showScreenCorners = false;
        forceBlackScreenCorners = true;
        radiusRatio = 0.8;
        enableShadows = true;
        shadowDirection = "bottom_right";
        lockOnSuspend = true;
        showChangelogOnStartup = false;
        telemetryEnabled = false;
      };
      ui = {
        fontDefault = "JetBrainsMono Nerd Font";
        fontFixed = "JetBrainsMono Nerd Font Mono";
        tooltipsEnabled = true;
        panelBackgroundOpacity = 0.85;
        panelsAttachedToBar = true;
        boxBorderEnabled = true;
      };
      colorSchemes = {
        darkMode = true;
      };
      location = {
        name = "Raleigh, NC";
        weatherEnabled = true;
        weatherShowEffects = false;
        useFahrenheit = true;
        use12hourFormat = true;
        showCalendarEvents = true;
        showCalendarWeather = true;
        firstDayOfWeek = 0;
      };
      notifications = {
        enabled = true;
        monitors = ["DP-3"];
      };
      wallpaper = {
        enabled = true;
        directory = "/home/kaika/Pictures/Wallpapers";
        setWallpaperOnAllMonitors = true;
        fillMode = "crop";
        fillColor = "#0c0e14";
        randomEnabled = false;
        transitionDuration = 1500;
        transitionType = "random";
        panelPosition = "follow_bar";
      };
      systemMonitor = {
        enableDgpuMonitoring = true;
        gpuPollingInterval = 2000;
      };
      dock = {
        enable = false;
      };
      appLauncher = {
        iconMode = "system";
        sortByMostUsed = true;
        terminalCommand = "kitty -e";
      };
      desktopWidgets = {
        enable = false;
      };
    };

    colors = {
      mPrimary = "#38bdf8";
      mOnPrimary = "#0c0e14";
      mPrimaryContainer = "#1e3a5f";
      mOnPrimaryContainer = "#e0e6f0";
      mSecondary = "#a78bfa";
      mOnSecondary = "#0c0e14";
      mSecondaryContainer = "#2d2547";
      mOnSecondaryContainer = "#e0e6f0";
      mTertiary = "#f59e0b";
      mOnTertiary = "#0c0e14";
      mTertiaryContainer = "#5c3d0a";
      mOnTertiaryContainer = "#e0e6f0";
      mError = "#f87171";
      mOnError = "#0c0e14";
      mErrorContainer = "#5c1a1a";
      mOnErrorContainer = "#fca5a5";
      mBackground = "#0c0e14";
      mOnBackground = "#e0e6f0";
      mSurface = "#0c0e14";
      mOnSurface = "#e0e6f0";
      mSurfaceVariant = "#141620";
      mOnSurfaceVariant = "#e0e6f0";
      mOutline = "#262a3a";
      mOutlineVariant = "#3a3f52";
      mShadow = "#000000";
      mScrim = "#000000";
      mInverseSurface = "#e0e6f0";
      mInverseOnSurface = "#0c0e14";
      mInversePrimary = "#0e7490";
      mSurfaceDim = "#0c0e14";
      mSurfaceBright = "#1e2030";
      mSurfaceContainerLowest = "#06080c";
      mSurfaceContainerLow = "#0c0e14";
      mSurfaceContainer = "#141620";
      mSurfaceContainerHigh = "#1e2030";
      mSurfaceContainerHighest = "#262a3a";
    };
  };

  # ===========================================================================
  # DOTFILES - Direct symlinks to repo (editable without rebuild)
  # ===========================================================================

  xdg.configFile = {
    "niri".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/niri";
    # waybar, mako, fuzzel, swaylock, swayidle replaced by Noctalia Shell
    "cava".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/cava";
    "fastfetch".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/fastfetch";
    "yazi".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/yazi";
    "alacritty".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/alacritty";
    "btop".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/btop";
  };

  # ===========================================================================
  # SCRIPTS - Direct symlinks to repo
  # ===========================================================================

  home.file = {
    ".local/bin/night-mode".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/local/bin/night-mode";
    ".local/bin/screenrecord".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/local/bin/screenrecord";
    ".local/bin/toggle-mode".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/local/bin/toggle-mode";
    ".local/bin/webapp-install".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/local/bin/webapp-install";
    ".local/bin/webapp-remove".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/local/bin/webapp-remove";
    ".local/bin/webapp-list".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/local/bin/webapp-list";
    ".local/bin/backup".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/local/bin/backup";
    ".local/bin/zoho-workdrive".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/local/bin/zoho-workdrive";

    # Thunderbird Frost Peak CSS
    ".thunderbird/frost-peak/chrome/userChrome.css".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/thunderbird/userChrome.css";
    ".thunderbird/frost-peak/chrome/userContent.css".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/thunderbird/userContent.css";
  };

  # ===========================================================================
  # GIT
  # ===========================================================================

  programs.git = {
    enable = true;
    settings = {
      user.name = "kaika";
      user.email = "kaikaapro@gmail.com";
      init.defaultBranch = "main";
      pull.rebase = false;
    };
  };

  # ===========================================================================
  # FISH SHELL
  # ===========================================================================

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
      nrs = "sudo nixos-rebuild switch --flake ~/nix-config#nixos";
      nrt = "sudo nixos-rebuild test --flake ~/nix-config#nixos";
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
      set fish_greeting ""
      fish_add_path ~/.local/bin
      fish_add_path ~/.npm-global/bin
      # Frost Peak fish colors
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

  # ===========================================================================
  # THUNAR - enforce list view
  # ===========================================================================

  home.activation.thunarConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    thunarrc="$HOME/.config/Thunar/thunarrc"
    mkdir -p "$(dirname "$thunarrc")"
    cat > "$thunarrc" << 'THUNARRC'
[Configuration]
DefaultView=ThunarDetailsView
LastView=ThunarDetailsView
THUNARRC

    xfconfxml="$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/thunar.xml"
    mkdir -p "$(dirname "$xfconfxml")"
    cat > "$xfconfxml" << 'XFCONFXML'
<?xml version="1.1" encoding="UTF-8"?>

<channel name="thunar" version="1.0">
  <property name="default-view" type="string" value="ThunarDetailsView"/>
  <property name="last-view" type="string" value="ThunarDetailsView"/>
</channel>
XFCONFXML
  '';

  # ===========================================================================
  # KITTY - Frost Peak theme
  # ===========================================================================

  programs.kitty = {
    enable = true;
    settings = {
      background_opacity = "0.92";
      window_padding_width = 12;
      confirm_os_window_close = 0;

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

      color0 = "#262a3a";
      color1 = "#f87171";
      color2 = "#34d399";
      color3 = "#f59e0b";
      color4 = "#38bdf8";
      color5 = "#a78bfa";
      color6 = "#22d3ee";
      color7 = "#e0e6f0";

      color8 = "#3a3f52";
      color9 = "#fca5a5";
      color10 = "#6ee7b7";
      color11 = "#fbbf24";
      color12 = "#7dd3fc";
      color13 = "#c4b5fd";
      color14 = "#67e8f9";
      color15 = "#ffffff";

      cursor_shape = "block";
      cursor_blink_interval = 0;
      shell_integration = "enabled";
    };
  };

  # ===========================================================================
  # CLI TOOLS
  # ===========================================================================

  programs.neovim = {
    enable = true;
    defaultEditor = false;
    viAlias = true;
    vimAlias = true;
    extraLuaConfig = ''
      -- Options
      vim.opt.number = true
      vim.opt.relativenumber = true
      vim.opt.mouse = "a"
      vim.opt.clipboard = "unnamedplus"
      vim.opt.ignorecase = true
      vim.opt.smartcase = true
      vim.opt.expandtab = true
      vim.opt.shiftwidth = 2
      vim.opt.tabstop = 2
      vim.opt.termguicolors = true
      vim.opt.scrolloff = 8
      vim.opt.signcolumn = "yes"
      vim.opt.cursorline = true
      vim.opt.showmode = false
      vim.opt.splitbelow = true
      vim.opt.splitright = true
      vim.opt.undofile = true
      vim.opt.updatetime = 250
      vim.opt.wrap = false

      -- Frost Peak colorscheme
      vim.cmd("highlight Normal guibg=#0c0e14 guifg=#e0e6f0")
      vim.cmd("highlight NormalFloat guibg=#141620 guifg=#e0e6f0")
      vim.cmd("highlight FloatBorder guibg=#141620 guifg=#262a3a")
      vim.cmd("highlight CursorLine guibg=#141620")
      vim.cmd("highlight CursorLineNr guifg=#38bdf8 gui=bold")
      vim.cmd("highlight LineNr guifg=#3a3f52")
      vim.cmd("highlight Visual guibg=#1e3a5f")
      vim.cmd("highlight Search guibg=#1e3a5f guifg=#38bdf8")
      vim.cmd("highlight IncSearch guibg=#38bdf8 guifg=#0c0e14")
      vim.cmd("highlight Pmenu guibg=#141620 guifg=#e0e6f0")
      vim.cmd("highlight PmenuSel guibg=#1e3a5f guifg=#38bdf8")
      vim.cmd("highlight StatusLine guibg=#141620 guifg=#e0e6f0")
      vim.cmd("highlight StatusLineNC guibg=#0c0e14 guifg=#3a3f52")
      vim.cmd("highlight VertSplit guifg=#262a3a guibg=NONE")
      vim.cmd("highlight SignColumn guibg=#0c0e14")
      vim.cmd("highlight Comment guifg=#3a3f52 gui=italic")
      vim.cmd("highlight String guifg=#34d399")
      vim.cmd("highlight Keyword guifg=#a78bfa gui=bold")
      vim.cmd("highlight Function guifg=#38bdf8")
      vim.cmd("highlight Type guifg=#22d3ee")
      vim.cmd("highlight Constant guifg=#f59e0b")
      vim.cmd("highlight Number guifg=#f59e0b")
      vim.cmd("highlight Boolean guifg=#f59e0b")
      vim.cmd("highlight Operator guifg=#22d3ee")
      vim.cmd("highlight Identifier guifg=#e0e6f0")
      vim.cmd("highlight Statement guifg=#a78bfa gui=bold")
      vim.cmd("highlight PreProc guifg=#38bdf8")
      vim.cmd("highlight Special guifg=#f59e0b")
      vim.cmd("highlight Error guifg=#f87171 guibg=NONE")
      vim.cmd("highlight WarningMsg guifg=#f59e0b")
      vim.cmd("highlight DiagnosticError guifg=#f87171")
      vim.cmd("highlight DiagnosticWarn guifg=#f59e0b")
      vim.cmd("highlight DiagnosticInfo guifg=#38bdf8")
      vim.cmd("highlight DiagnosticHint guifg=#22d3ee")
      vim.cmd("highlight MatchParen guibg=#262a3a guifg=#38bdf8 gui=bold")
      vim.cmd("highlight TabLine guibg=#141620 guifg=#3a3f52")
      vim.cmd("highlight TabLineSel guibg=#1e3a5f guifg=#38bdf8 gui=bold")
      vim.cmd("highlight TabLineFill guibg=#0c0e14")
      vim.cmd("highlight Title guifg=#38bdf8 gui=bold")
      vim.cmd("highlight Directory guifg=#38bdf8")
      vim.cmd("highlight NonText guifg=#262a3a")
      vim.cmd("highlight EndOfBuffer guifg=#0c0e14")

      -- Statusline
      vim.opt.statusline = " %f %m%r %= %y  %l:%c  %p%% "
    '';
  };

  programs.bat = {
    enable = true;
    config = { theme = "TwoDark"; paging = "auto"; };
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.tmux = {
    enable = true;
    terminal = "tmux-256color";
    mouse = true;
    baseIndex = 1;
    escapeTime = 0;
    historyLimit = 10000;
    keyMode = "vi";
    prefix = "C-a";
    plugins = with pkgs.tmuxPlugins; [
      {
        plugin = resurrect;
        extraConfig = "set -g @resurrect-strategy-nvim 'session'";
      }
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '10'
        '';
      }
    ];
    extraConfig = ''
      # Frost Peak status bar
      set -g status-style "bg=#141620,fg=#e0e6f0"
      set -g status-left "#[bg=#38bdf8,fg=#0c0e14,bold] #S #[default] "
      set -g status-right "#[fg=#a78bfa]%H:%M #[fg=#3a3f52]| #[fg=#38bdf8]%b %d"
      set -g window-status-current-style "bg=#1e3a5f,fg=#38bdf8,bold"
      set -g window-status-style "fg=#3a3f52"
      set -g pane-border-style "fg=#262a3a"
      set -g pane-active-border-style "fg=#38bdf8"
      set -g message-style "bg=#141620,fg=#38bdf8"

      # True color support
      set -ag terminal-overrides ",xterm-256color:RGB"

      # Split panes with | and -
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      bind c new-window -c "#{pane_current_path}"

      # Vi-style pane navigation
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R
    '';
  };

  # ===========================================================================
  # STARSHIP PROMPT - Frost Peak style
  # ===========================================================================

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

  # ===========================================================================
  # GTK - Frost Peak theme
  # ===========================================================================

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

  # ===========================================================================
  # QT
  # ===========================================================================

  qt = {
    enable = true;
    platformTheme.name = "adwaita";
    style.name = "adwaita-dark";
  };

  # ===========================================================================
  # VSCODE
  # ===========================================================================

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
  };

  # ===========================================================================
  # THUNDERBIRD - Frost Peak theme
  # ===========================================================================

  programs.thunderbird = {
    enable = true;
    profiles.frost-peak = {
      isDefault = true;
      settings = {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "ui.systemUsesDarkTheme" = 1;
        "browser.display.background_color" = "#0c0e14";
        "browser.display.foreground_color" = "#e0e6f0";
        "browser.display.use_system_colors" = false;
        "mail.pane_config.dynamic" = 0;
        "mailnews.default_sort_order" = 2;
        "mailnews.default_sort_type" = 18;
        "font.name.sans-serif.x-western" = "Noto Sans";
        "font.name.monospace.x-western" = "JetBrainsMono Nerd Font";
        "mailnews.message_display.disable_remote_image" = true;
      };
    };
  };

  # ===========================================================================
  # ENVIRONMENT & XDG
  # ===========================================================================

  home.sessionVariables = {
    EDITOR = "code";
    VISUAL = "code";
    TERMINAL = "kitty";
    BROWSER = "firefox";
    QS_ICON_THEME = "Papirus-Dark";
  };

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

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "firefox.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "x-scheme-handler/about" = "firefox.desktop";
      "x-scheme-handler/unknown" = "firefox.desktop";
      "x-scheme-handler/mailto" = "thunderbird.desktop";
      "message/rfc822" = "thunderbird.desktop";
      "x-scheme-handler/mid" = "thunderbird.desktop";
    };
  };
}
