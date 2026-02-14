# Home Manager configuration for kaika
# Extracted from the monolithic configuration-noflake.nix
# Programs here generate Nix-managed configs (kitty, starship, fish, etc.)
# Dotfiles in config/ are symlinked directly via mkOutOfStoreSymlink (live-editable)

{ config, pkgs, lib, ... }:

let
  # Absolute path to the nix-config repo (~/nix-config symlink)
  # Used by mkOutOfStoreSymlink to create direct symlinks to repo files
  dotfilesPath = "/home/kaika/nix-config";
in
{
  home.stateVersion = "24.11";
  home.enableNixpkgsReleaseCheck = false;

  home.packages = with pkgs; [];

  # ===========================================================================
  # DOTFILES - Direct symlinks to repo (editable without rebuild)
  # ===========================================================================

  xdg.configFile = {
    "niri".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/niri";
    "waybar".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/waybar";
    "mako".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/mako";
    "fuzzel".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/fuzzel";
    "swaylock".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/swaylock";
    "swayidle".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/swayidle";
    "cava".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/cava";
    "fastfetch".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/fastfetch";
    "yazi".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/yazi";
    "alacritty".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/alacritty";
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
