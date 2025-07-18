{
  config,
  lib,
  pkgs,
  ...
}:
#############################
# Enable Development Apps
#############################
let
  # An object containing user configuration (in /etc/nixos/configuration.nix)
  cfg = config.extraServices.development_apps;
in {
  # Create the main option to toggle the service state
  options.extraServices.development_apps = {
    enable = lib.mkEnableOption "development_apps";
  };

  # Everything that should be done when/if the service is enabled
  config = lib.mkIf cfg.enable {
    # Packages
    environment.systemPackages = with pkgs; [
      # Terminal Tools
      pulumi # For deployments
      pulumiPackages.pulumi-python

      # Development - pre-commit related
      alejandra # Like python's black but for nix files
      detect-secrets
      nodejs_24 # Needed by some pre-commit hooks
      pre-commit
      statix # Like Python's flake8 but for nix files
      deadnix

      # Development
      cargo # Rust
      dotnetCorePackages.dotnet_9.sdk # C#
      gcc
      godot
      godot-mono
      libgcc
      python3
      python310
      python311
      python312
      python313
      jetbrains.pycharm-community-bin
      rustc # Rust
      stdenv.cc.cc.lib
      (vscode-with-extensions.override {
        vscodeExtensions = with vscode-extensions; [
          esbenp.prettier-vscode # Prettier
          github.vscode-github-actions
          hashicorp.terraform
          jnoortheen.nix-ide # Nix
          kamadorueda.alejandra # Nix
          ms-azuretools.vscode-docker
          ms-dotnettools.csdevkit # C#
          ms-dotnettools.csharp # C#
          ms-dotnettools.vscode-dotnet-runtime # C#
          ms-python.debugpy # Python
          ms-python.mypy-type-checker # Python
          ms-python.python # Python
          ms-python.vscode-pylance # Python
          ms-vscode-remote.remote-ssh
          ms-vscode-remote.vscode-remote-extensionpack
          streetsidesoftware.code-spell-checker
        ];
      })
    ];
  };
}
