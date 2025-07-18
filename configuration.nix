{
  config,
  lib,
  pkgs,
  ...
}: let
  # Load the settings from the secrets file
  settings = import ./settings.nix;

  # Check if an extra username has been setup
  hasValidUser = settings.username != "" && settings.password != "";
in {
  # Import the qemu-guest.nix file from the nixpkgs repository on GitHub
  #   https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/profiles/qemu-guest.nixC
  imports = [
    # arion.nixosModules.arion

    # "${builtins.fetchTarball "https://github.com/hercules-ci/arion/archive/refs/tags/v0.2.1.0.tar.gz"}/nixos-module.nix"
    "${builtins.fetchTarball "https://github.com/nixos/nixpkgs/archive/master.tar.gz"}/nixos/modules/profiles/qemu-guest.nix"
    ./hardware-configuration.nix
    ./extra_services
  ];

  # Location
  time.timeZone = settings.timezone;

  # Packages
  environment.systemPackages = with pkgs; [
    # Terminal Tools
    bat
    git
    nano
    par2cmdline
    pciutils # For lspci - Since this is a VM we might pass PCI devices to, this helps troubleshoot that
    tmux
    tree
    unrar
    unzip
    wget

    # Docker
    docker
    docker-compose
    kubectl

    # Nix
    nix
  ];

  # Default Boot options
  fileSystems."/" = {
    label = "nixos";
    fsType = "ext4";
    autoResize = true;
  };
  boot.loader.grub.device = "/dev/sda";

  # SSH should always be available
  services.openssh.enable = true;

  # For VMs
  services.qemuGuest.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  security.sudo.wheelNeedsPassword = false;

  # Get serial console working (not sure this is still needed)
  systemd.services."getty@tty1" = {
    enable = lib.mkForce true;
    wantedBy = ["getty.target"]; # to start at boot
    serviceConfig.Restart = "always"; # restart when session is closed
  };

  # Setup nerd font
  fonts = {
    enableDefaultPackages = true;
    fontconfig.enable = true;

    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
    ];
  };

  virtualisation.docker.enable = true;

  # Enable experimental features we will need
  nix.settings = {
    #download-buffer-size = 10485760;
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  programs.zsh.enable = true;

  # Setup ops group
  users.groups.ops = {
    gid = 1000; # Set the gid
  };

  users.users = lib.mkMerge [
    {
      # Setup ops user for ssh'ing into the box
      ops = {
        isNormalUser = true;
        uid = 1000; # Set the uid
        group = "ops"; # Primary group for the user
        extraGroups = [
          "wheel"
        ];
        home = "/home/ops"; # Ensure the home directory is set
      };
    }

    # Generate the extra username configured
    (lib.mkIf hasValidUser (
      lib.genAttrs [settings.username] (_: {
        isNormalUser = true;
        createHome = true;
        group = "ops";
        extraGroups = ["wheel"];
        shell = pkgs.zsh;
        password = settings.password;
        home = "/home/${settings.username}";
      })
    ))
  ];

  networking = {
    # defaultGateway = { address = "10.1.1.1"; interface = "eth0"; };
    dhcpcd.enable = false;
    interfaces.eth0.useDHCP = false;
  };

  systemd.network.enable = true;

  #############################
  # have updatedb run weekly Friday Early Morning
  # This is what populates the `locate` command
  #############################
  services.locate = {
    enable = true;
    interval = "Fri *-*-* 02:15:00";
    package = pkgs.plocate;
    pruneNames = [".bzr" ".cache" ".git" ".hg" ".mozilla" ".npm" ".rbenv" ".svn" ".venv" "Plex Media Server"];
    pruneFS = [
      "afs"
      "anon_inodefs"
      "auto"
      "autofs"
      "bdev"
      "binfmt"
      "binfmt_misc"
      "ceph"
      "cgroup"
      "cgroup2"
      # "cifs"  # We want to scan mounted systems
      "coda"
      "configfs"
      "cramfs"
      "cpuset"
      "curlftpfs"
      "debugfs"
      "devfs"
      "devpts"
      "devtmpfs"
      "ecryptfs"
      "eventpollfs"
      "exofs"
      "futexfs"
      "ftpfs"
      "fuse"
      "fusectl"
      "fusesmb"
      "fuse.ceph"
      "fuse.glusterfs"
      "fuse.gvfsd-fuse"
      "fuse.mfs"
      "fuse.rclone"
      "fuse.rozofs"
      "fuse.sshfs"
      "gfs"
      "gfs2"
      "hostfs"
      "hugetlbfs"
      "inotifyfs"
      "iso9660"
      "jffs2"
      "lustre"
      "lustre_lite"
      "misc"
      "mfs"
      "mqueue"
      "ncpfs"
      "nfs"
      "NFS"
      "nfs4"
      "nfsd"
      "nnpfs"
      "ocfs"
      "ocfs2"
      "pipefs"
      "proc"
      "ramfs"
      "rpc_pipefs"
      "securityfs"
      "selinuxfs"
      "sfs"
      "shfs"
      "smbfs"
      "sockfs"
      "spufs"
      "sshfs"
      "subfs"
      "supermount"
      "sysfs"
      "tmpfs"
      "tracefs"
      "ubifs"
      "udev"
      "udf"
      "usbfs"
      "vboxsf"
      "vperfctrfs"
    ];
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  system.stateVersion = "25.05";

  #############################
  # Extra Services
  #############################

  # Cloud Init
  extraServices.cloud_init.enable = settings.cloud_init_enable;
  extraServices.cloud_init.username = settings.cloud_init_username;
  extraServices.cloud_init.password = settings.cloud_init_password;

  # Desktop apps
  extraServices.desktop_apps.enable = settings.desktop_apps_enable;

  # Development apps
  extraServices.development_apps.enable = settings.development_apps_enable;

  # Setup Glances
  extraServices.glances_with_prometheus.enable = settings.custom_glances_enable;

  extraServices.home_manager.enable = settings.home_manager_enable;
  extraServices.home_manager.username = settings.home_manager_username;
  extraServices.home_manager.git_username = settings.home_manager_git_username;
  extraServices.home_manager.git_email = settings.home_manager_git_email;

  # Setup Fileserver
  extraServices.fileserver.enable = settings.fileserver_enable;
  extraServices.fileserver.username = settings.fileserver_username;
  extraServices.fileserver.password = settings.fileserver_password;
  extraServices.fileserver.hosts_allow = settings.fileserver_hosts_allow;

  # Setup Games on Whales - Wolf
  extraServices.gow_wolf.enable = settings.gow_wolf_enable;
  extraServices.gow_wolf.gpu_type = settings.gow_wolf_gpu_type;

  # Setup GPU
  extraServices.gpu.enable = settings.gpu_enable;
  extraServices.gpu.gpu_type = settings.gpu_type;

  # Mount SMB Shares
  extraServices.mount_samba = {
    enable = settings.samba_mount_enable;
    username = settings.samba_mount_username;
    password = settings.samba_mount_password;
    path = settings.samba_mount_path;
    mount_location = settings.samba_mount_mount_location;
  };

  # Setup Kubernetes
  extraServices.single_node_kubernetes = {
    enable = settings.kube_single_node_enable;
    node_master_ip = settings.kube_master_ip;
    hostname = settings.kube_nix_hostname;
    full_hostname = settings.kube_master_hostname;
    nameserver_ip = settings.kube_resolv_conf_nameserver;
    api_server_port = settings.kube_master_api_server_port;
  };
}
