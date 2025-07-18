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
  cfg = config.extraServices.cloud_init;
in {
  # Create the main option to toggle the service state
  options.extraServices.cloud_init = {
    enable = lib.mkEnableOption "cloud_init";

    username = lib.mkOption {
      type = lib.types.str;
      example = "username";
      default = "ops";
    };

    # Not using this option yet as SSH keys are being setup
    password = lib.mkOption {
      type = lib.types.str;
      example = "password123";
    };
  };

  # Everything that should be done when/if the service is enabled
  config = lib.mkIf cfg.enable {
    # #############################
    # # Cloud init
    # #############################
    services.cloud-init = {
      enable = true;
      network.enable = true;
      config = ''
        system_info:
          distro: nixos
          network:
            renderers: [ 'networkd' ]
          default_user:
            name: ${cfg.username}
        users:
            - default
        ssh_pwauth: false
        chpasswd:
          expire: false
        cloud_init_modules:
          - migrator
          - seed_random
          - growpart
          - resizefs
        cloud_config_modules:
          - disk_setup
          - mounts
          - set-passwords
          - ssh
        cloud_final_modules: []
      '';
    };
  };
}
