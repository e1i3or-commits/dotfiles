{ config, pkgs, inputs, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should manage
  home.username = "kaika";
  home.homeDirectory = "/home/kaika";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  home.stateVersion = "24.11";

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # User packages (in addition to system packages)
  home.packages = with pkgs; [
    # Add any user-specific packages here
  ];

  # Git configuration
  programs.git = {
    enable = true;
    userName = "kaika";
    userEmail = "kaikaapro.com"; # Change this to your email
    extraConfig = {
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

      # NixOS shortcuts
      nrs = "sudo nixos-rebuild switch --flake /etc/nixos#nixos";
      nrt = "sudo nixos-rebuild test --flake /etc/nixos#nixos";

      # Modern CLI replacements
      cat = "bat";
      ls = "eza";
      ll = "eza -l";
      la = "eza -la";
      tree = "eza --tree";
    };
    shellAliases = {
      # CD replacements with zoxide
      cd = "z";
    };
    interactiveShellInit = ''
      # Initialize zoxide
      zoxide init fish | source

      # Set greeting
      set fish_greeting ""

      # Fish syntax highlighting colors
      set -g fish_color_autosuggestion brblack
      set -g fish_color_command green
      set -g fish_color_param normal
      set -g fish_color_error red
    '';
  };

  # Alacritty terminal configuration
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        opacity = 0.95;
        padding = {
          x = 10;
          y = 10;
        };
        decorations = "full";
      };

      font = {
        normal = {
          family = "JetBrainsMono Nerd Font";
          style = "Regular";
        };
        bold = {
          family = "JetBrainsMono Nerd Font";
          style = "Bold";
        };
        italic = {
          family = "JetBrainsMono Nerd Font";
          style = "Italic";
        };
        size = 11.0;
      };

      colors = {
        primary = {
          background = "#1e1e2e";
          foreground = "#cdd6f4";
        };
        normal = {
          black = "#45475a";
          red = "#f38ba8";
          green = "#a6e3a1";
          yellow = "#f9e2af";
          blue = "#89b4fa";
          magenta = "#f5c2e7";
          cyan = "#94e2d5";
          white = "#bac2de";
        };
        bright = {
          black = "#585b70";
          red = "#f38ba8";
          green = "#a6e3a1";
          yellow = "#f9e2af";
          blue = "#89b4fa";
          magenta = "#f5c2e7";
          cyan = "#94e2d5";
          white = "#a6adc8";
        };
      };

      cursor = {
        style = "Block";
        unfocused_hollow = true;
      };
    };
  };

  # Bat (cat replacement) configuration
  programs.bat = {
    enable = true;
    config = {
      theme = "TwoDark";
      paging = "auto";
    };
  };

  # Zoxide (smart cd) configuration
  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  # fzf (fuzzy finder) configuration
  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
  };

  # VSCode/VSCodium configuration
  programs.vscode = {
    enable = true;
    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        # Language support
        ms-python.python
        ms-vscode.cpptools

        # Nix support
        bbenoist.nix

        # Git integration
        eamodio.gitlens

        # Themes
        catppuccin.catppuccin-vsc
        pkief.material-icon-theme

        # Quality of life
        esbenp.prettier-vscode
        dbaeumer.vscode-eslint
      ];
      userSettings = {
        "editor.fontSize" = 13;
        "editor.fontFamily" = "'JetBrainsMono Nerd Font', monospace";
        "editor.fontLigatures" = true;
        "editor.minimap.enabled" = false;
        "editor.lineNumbers" = "on";
        "editor.renderWhitespace" = "selection";
        "workbench.colorTheme" = "Catppuccin Mocha";
        "workbench.iconTheme" = "material-icon-theme";
        "terminal.integrated.fontFamily" = "'JetBrainsMono Nerd Font'";
        "terminal.integrated.fontSize" = 12;
        "files.autoSave" = "afterDelay";
        "git.enableSmartCommit" = true;
        "git.confirmSync" = false;
      };
    };
  };

  # Niri configuration will be loaded from separate config file
  # See niri/config.kdl after installation

  # Environment variables
  home.sessionVariables = {
    EDITOR = "code";
    VISUAL = "code";
    TERMINAL = "alacritty";
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
}
