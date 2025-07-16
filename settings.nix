let
  # Load the JSON file only if it exists
  settingsFile =
    if builtins.pathExists "/etc/nixos/settings.json" then
      builtins.fromJSON (builtins.readFile (toString /etc/nixos/settings.json))
    else
      {};

  # Default values
  defaultSettings = {
    # Global Settings
    timezone = "America/Los_Angeles";
    gateway = "192.168.10.1";
    domain_name = "home.arpa";
    nameserver_ip = "192.168.10.1";
    username = "nixosuser";
    password = "changeme";

    internal_network_ip = "";
    internal_network_cidr = 24;

    # Cloud-init (default to true since we use a cloud-init image by default)
    cloud_init_enable = true;
    cloud_init_username = "ops";
    cloud_init_password = "";

    # Customized version of glances
    custom_glances_enable = false;

    # Desktop app
    desktop_apps_enable = false;

    # Fileserver settings
    fileserver_enable = false;
    fileserver_username = "samba-user";
    fileserver_password = "";
    fileserver_hosts_allow = "192.168.1. 192.168.10. 192.168.100. 127.0.0.1 localhost";

    # Setup GPU
    gpu_enable = false;
    gpu_gpu_type = "";

    # Games on Whales - Wolf
    gow_wolf_enable = false;
    gow_wolf_gpu_type = "software";

    home_manager_enable = false;
    home_manager_username = "";
    home_manager_git_username = "";
    home_manager_git_email = "";

    # Samba mount settings
    samba_mount_enable = false;
    samba_mount_path = "";
    samba_mount_mount_location = "";
    samba_mount_username = "";
    samba_mount_password = "";

    # Kubernetes Settings
    kube_single_node_enable = false;
    kube_master_ip = "";
    kube_nix_hostname = "";
    kube_master_hostname = "";
    kube_resolv_conf_nameserver = "";
    kube_master_api_server_port = 6443;
  };

  # Merge attrsets; right-hand wins (overrides)
  settings = defaultSettings // settingsFile;

in settings
