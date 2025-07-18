{
  config,
  lib,
  pkgs,
  ...
}:
#############################
# Enable Cloud-init
#############################
let
  # An object containing user configuration (in /etc/nixos/configuration.nix)
  cfg = config.extraServices.desktop_apps;

  # Get older version of transmission
  transmission405Pkgs = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/0c19708cf035f50d28eb4b2b8e7a79d4dc52f6bb.tar.gz";
    sha256 = "0ngw2shvl24swam5pzhcs9hvbwrgzsbcdlhpvzqc7nfk8lc28sp3";
  }) {};
in {
  # Create the main option to toggle the service state
  options.extraServices.desktop_apps = {
    enable = lib.mkEnableOption "desktop_apps";
  };

  # Everything that should be done when/if the service is enabled
  config = lib.mkIf cfg.enable {
    # Packages
    environment.systemPackages = with pkgs; [
      # Core thumbnailers
      gdk-pixbuf # for basic image thumbnails
      ffmpegthumbnailer # for video thumbnails
      thud
      xfce.tumbler # generic thumbnail generator used by XFCE and MATE

      # Optional thumbnail helpers
      imagemagick # general image processing
      libopenraw # raw image formats
      poppler_utils # PDF thumbnails (via `pdftoppm`)

      # Dropbox
      dropbox
      mate.caja-dropbox
      maestral
      maestral-gui

      # Internet
      chromium
      filezilla
      uget
      vivaldi

      # File Management (gives us access to bulk-rename application)
      xfce.thunar

      # Torrents
      #transmission_4-qt

      # Transmission 4.0.5 from pinned nixpkgs
      transmission405Pkgs.transmission_4-qt

      # Office
      libreoffice-qt-fresh

      # Terminal Tools
      gdm
      ghostty
      lastpass-cli
      pulumi # For deployments
      pulumiPackages.pulumi-python

      # Image
      shotwell

      nix

      # Audio
      plexamp
      pulseaudio

      # Desktop
      xorg.xinit
      xorg.xauth
      vlc

      # Development - pre-commit related
      alejandra
      detect-secrets
      nodejs_24 # Needed by some pre-commit hooks
      pre-commit
      statix
      deadnix

      # Development
      dotnetCorePackages.dotnet_9.sdk
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
      stdenv.cc.cc.lib
      (vscode-with-extensions.override {
        vscodeExtensions = with vscode-extensions; [
          esbenp.prettier-vscode
          github.vscode-github-actions
          hashicorp.terraform
          jnoortheen.nix-ide
          ms-azuretools.vscode-docker
          ms-dotnettools.csdevkit
          ms-dotnettools.csharp
          ms-dotnettools.vscode-dotnet-runtime
          ms-python.debugpy
          ms-python.mypy-type-checker
          ms-python.python
          ms-python.vscode-pylance
          ms-vscode-remote.remote-ssh
          ms-vscode-remote.vscode-remote-extensionpack
          streetsidesoftware.code-spell-checker
        ];
      })
    ];

    # Add thunar's bulk-rename utility to the desktop
    environment.etc."xdg/applications/thunar-bulk-rename.desktop".text = ''
      [Desktop Entry]
      Version=1.0
      Type=Application
      Name=Bulk Rename
      Comment=Rename multiple files
      Exec=thunar -B
      Icon=thunar
      Terminal=false
      Categories=System;Utility;
    '';

    # Browser Extensions - This is how we get extensions to install (including in Vivaldi)
    programs.chromium = {
      enable = true;
      extensions = [
        "hdokiejnpimakedhajhdlcegeplioahd" # Lastpass
        "imfcckkmcklambpijbgcebggegggkgla" # Monarch
        "aapbdbdomjkkjkaonfhkkikfgjllcleb" # Google Translate
      ];
    };

    # nix never adds anything to the LD_LIBRARY_PATH, but we need some stuff in there
    environment.sessionVariables = {
      LD_LIBRARY_PATH = "${pkgs.stdenv.cc.cc.lib}/lib";
    };

    # Give file managers ability to browse Samba shares
    services.gvfs.enable = true;

    #############################
    # Remote Desktop
    #############################
    # Should probably make this a different module, but all of my stuff is headless
    services.xserver = {
      enable = true;
      displayManager.lightdm.enable = true; # Use LightDM (instead of GDM or SDDM)
      desktopManager.mate.enable = true; # Enable MATE desktop environment
    };

    services.xrdp = {
      enable = true;
      audio.enable = true;
      defaultWindowManager = "mate-session"; # Use MATE session as the default window manager
      openFirewall = true;
    };

    # Enable PulseAudio (Need to setup some "fake" audio so we can hear it)
    # Configure PulseAudio to work with XRDP
    services.pipewire.enable = false;
    services.pulseaudio = {
      enable = true;
      # Use PulseAudio's virtual sound card
      extraConfig = ''
        load-module module-null-sink sink_name=VirtualAudio
        load-module module-raop-discover
      '';
    };
  };
}
