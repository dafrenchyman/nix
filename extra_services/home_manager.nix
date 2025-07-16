{ config, lib, pkgs, ... }:

#############################
# Enable Home Manager
#############################

let
  # An object containing user configuration (in /etc/nixos/configuration.nix)
  cfg = config.extraServices.home_manager;

  home-manager = builtins.fetchTarball https://github.com/nix-community/home-manager/archive/release-25.05.tar.gz;

  homeManagerPath = builtins.fetchTarball {
    url = "https://github.com/nix-community/home-manager/archive/release-25.05.tar.gz";
  };
  
in {

  imports = [
    (import "${homeManagerPath}/nixos")
  ];
  
  options.extraServices.home_manager = {
    # Create the main option to toggle the service state
    enable = lib.mkEnableOption "home_manager";

    username = lib.mkOption {
      type = lib.types.str;
      example = "someuser";
    };

    git_username = lib.mkOption {
      type = lib.types.str;
      example = "someuser";
    };

    git_email = lib.mkOption {
      type = lib.types.str;
      example = "someuser@email.com";
    };
  };

  # Everything that should be done when/if the service is enabled
  config = lib.mkIf cfg.enable {

    home-manager.users.${cfg.username} = { pkgs, ... }: {
      home.packages = [ pkgs.atool pkgs.httpie ];
    
      # The state version is required and should stay at the version you
      # originally installed.
      home.stateVersion = "25.05";

      programs.fzf = {
        enable = true;
        enableBashIntegration = true;
        enableZshIntegration = true;
        # tmux.enableShellIntegration = true;
        defaultOptions = [
            "--no-mouse"
        ];
      };

      programs.git = {
        enable = true;
        userName = cfg.git_username;
        userEmail = cfg.git_email;
      };

      programs.zsh = {
        enable = true;
        enableCompletion = true;
        autosuggestion.enable = true;

        syntaxHighlighting.enable = true;
        # history.append = true;
        history.expireDuplicatesFirst = true;
        history.findNoDups = true;
        history.ignoreAllDups = true;
        history.ignoreSpace = true;  # Do not enter command lines into the history list that start with a space

        oh-my-zsh = {
          enable = true;
          plugins = [
            "docker"
            "docker-compose"
            "fzf"
            "git"
            "npm"
            "node"
            "z"
          ];  # Plugins to use
          theme = "";  # disable oh-my-zsh prompt theme
        };

        initContent = ''
          # Tell oh-my-zsh to not set its own prompt
          unsetopt promptcr

          # Set up oh-my-posh as prompt
          # eval "$(oh-my-posh init zsh --config ~/.poshthemes/jandedobbeleer.omp.json)"

          # Fix caja thumbnail issue
          export OPENBLAS_NUM_THREADS=1

        '';

      };

      programs.tmux = {
        enable = true;
        shell = "${pkgs.zsh}/bin/zsh";
        mouse = true;
        terminal = "tmux-256color";
        extraConfig = ''
          set -g history-limit 10000
          set -g default-terminal "tmux-256color"
          set -ga terminal-overrides ",xterm-256color:Tc"
        '';
      };

      # Use this for the terminal theme
      programs.oh-my-posh = {
        enable = true;
        enableZshIntegration = true;
        enableBashIntegration = false;
        useTheme = "powerlevel10k_rainbow";

      };

      programs.autojump = {
        enable = true;
        enableZshIntegration = true;
        enableBashIntegration = false;
      };

    };
  };
}