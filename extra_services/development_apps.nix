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

  home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/release-25.05.tar.gz";
  homeManagerPath = builtins.fetchTarball {
    url = "https://github.com/nix-community/home-manager/archive/release-25.05.tar.gz";
  };

  # Install godot version of vscode
  install_godot_vscode = false;
in {
  # Create the main option to toggle the service state
  options.extraServices.development_apps = {
    enable = lib.mkEnableOption "development_apps";

    username = lib.mkOption {
      type = lib.types.str;
      example = "someuser";
    };
  };

  # Everything that should be done when/if the service is enabled
  config = lib.mkIf cfg.enable {
    # Packages
    environment.systemPackages = with pkgs; [
      # Terminal Tools
      pulumi # For deployments
      pulumiPackages.pulumi-python

      # Development - pre-commit related
      alejandra # Nix - Like python's black but for nix files
      deadnix # Nix - Looks for unused stuff
      detect-secrets # Checks you don't accidentally commit secrets to git
      nodejs_24 # Needed by some pre-commit hooks
      pre-commit
      statix # Nix - Like Python's flake8 but for nix files

      # Development
      cargo #
      #dotnet-sdk
      dotnetCorePackages.dotnet_9.sdk # C#
      gcc
      godot
      godot-mono
      jetbrains.rider
      libgcc
      python3
      python310
      python311
      python312
      python312Packages.pip
      python312Packages.virtualenv
      python313
      python313Packages.pip
      python313Packages.virtualenv
      jetbrains.pycharm-community-bin
      rustc # Rust
      stdenv.cc.cc.lib
      # vscode
      # (vscode-with-extensions.override {
      #   vscodeExtensions = with vscode-extensions;
      #     [
      #       esbenp.prettier-vscode # Prettier
      #       github.vscode-github-actions
      #       hashicorp.terraform
      #       jnoortheen.nix-ide # Nix
      #       kamadorueda.alejandra # Nix
      #       ms-azuretools.vscode-docker
      #       #ms-dotnettools.csdevkit # C#
      #       #ms-dotnettools.csharp # C#
      #       #ms-dotnettools.vscode-dotnet-runtime # C#
      #       #ms-python.mypy-type-checker
      #       ms-vscode-remote.remote-ssh
      #       ms-vscode-remote.vscode-remote-extensionpack
      #       streetsidesoftware.code-spell-checker
      #       # New Python extensions currently broken
      #       #ms-python.python
      #       #ms-python.debugpy
      #       #ms-python.vscode-pylance
      #     ]
      #     # Some of the newer versions of extensions are broken - Install specific versions instead
      #     ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
      #       {
      #         name = "csdevkit";
      #         publisher = "ms-dotnettools";
      #         version = "1.16.6";
      #         sha256 = "9+EdLLmcDV6W+2MSAbtYY9nCeWeIV4y88UB+TiqVuOU=";  # pragma: allowlist secret
      #       }
      #       {
      #         name = "csharp";
      #         publisher = "ms-dotnettools";
      #         version = "2.63.32";
      #         sha256 = "d77S13UzAvHF9JBoi/wzh1EDjVAQ6/KugT/zHl6Aj+U=";  # pragma: allowlist secret
      #       }
      #       {
      #         name = "vscode-dotnet-runtime";
      #         publisher = "ms-dotnettools";
      #         version = "2.2.8";
      #         sha256 = "l+/r0C+BZr8H8qBKenVP3b4qYGR57Lol+Y1Q2XUGl24=";  # pragma: allowlist secret
      #       }
      #       {
      #         name = "debugpy";
      #         publisher = "ms-python";
      #         version = "2025.4.0";
      #         sha256 = "WbnR949zHuoW+jR6vugvHussScBvgRIi8PYi9HbJxjc=";  # pragma: allowlist secret
      #       }
      #       {
      #         name = "python";
      #         publisher = "ms-python";
      #         version = "2025.4.0";
      #         sha256 = "/yQbmZTnkks1gvMItEApRzfk8Lczjq+JC5rnyJxr6fo=";  # pragma: allowlist secret
      #       }
      #       {
      #         name = "vscode-pylance";
      #         publisher = "ms-python";
      #         version = "2025.4.1";
      #         sha256 = "XZ00HOH+7onP1li6nBwjBIRc1Zy5SNvrT1JhnzJTr1E=";  # pragma: allowlist secret
      #       }
      #     ];
      # })
    ];

    # Add the custom VScode Godot
    # environment.etc."xdg/applications/vscode-for-godot.desktop".text = lib.mkIf install_godot_vscode ''
    #   [Desktop Entry]
    #   Version=1.0
    #   Type=Application
    #   Name=Visual Studio Code for C# (Godot)
    #   Comment=Special Version of VScode for C# and Godot programming
    #   Exec=vscode-godot-csharp
    #   Icon=code
    #   Terminal=false
    #   Categories=Development;IDE;
    # '';

    home-manager.useUserPackages = true;
    home-manager.backupFileExtension = "backup";

    home-manager.users.${cfg.username} = {pkgs, ...}: {
      nixpkgs.config.allowUnfree = true;

      # Regular vscode
      programs.vscode = {
        enable = true;

        # Optional: install extensions from the marketplace
        extensions = with pkgs.vscode-extensions; [
          esbenp.prettier-vscode # Prettier
          github.vscode-github-actions
          hashicorp.terraform
          jnoortheen.nix-ide # Nix
          kamadorueda.alejandra # Nix
          ms-azuretools.vscode-docker
          ms-dotnettools.csdevkit # C#
          ms-dotnettools.csharp # C#
          ms-dotnettools.vscode-dotnet-runtime # C#
          ms-python.mypy-type-checker
          ms-vscode-remote.remote-ssh
          ms-vscode-remote.vscode-remote-extensionpack
          streetsidesoftware.code-spell-checker
          ms-python.python
          ms-python.debugpy
          ms-python.vscode-pylance
        ];

        # Optional: use system-wide vscode or one from nixpkgs
        #package = pkgs.vscode; # or pkgs.vscodium if you prefer
      };

      # Special vscode for godot-mono
      home.packages = lib.mkIf install_godot_vscode [
        pkgs.atool
        pkgs.httpie
        (pkgs.buildFHSUserEnvBubblewrap {
          name = "vscode-godot-csharp";
          targetPkgs = pkgs:
            with pkgs; [
              dotnetCorePackages.dotnet_9.sdk # C#
              gcc
              godot
              godot-mono
              libgcc
              vscode
            ];
          runScript = "code";
        })
      ];

      # Add a desktop entry for MATE
      # xdg.desktopEntries.vscode-godot-csharp = {
      #   name = "VSCode (Godot C#)";
      #   genericName = "Visual Studio Code for Godot";
      #   comment = "Launch VSCode with FHS environment for Godot and C# support";
      #   exec = "vscode-godot-csharp";
      #   terminal = false;
      #   categories = ["Development" "IDE"];
      #   icon = "code"; # You can use "code", or path to a custom icon
      # };
    };
  };
}
