{ config, lib, pkgs, ... }:

#############################
# Setup samba server
#############################
# From here:
#  https://nixos.wiki/wiki/Samba
#  https://sourcegraph.com/github.com/Icy-Thought/snowflake/-/blob/modules/networking/samba.nix
#  https://sourcegraph.com/github.com/wkennington/nixos/-/blob/nas/samba.nix

let
  # An object containing user configuration (in /etc/nixos/configuration.nix)
  cfg = config.extraServices.fileserver;
in {
  # Create the main option to toggle the service state
  options.extraServices.fileserver = {
    enable = lib.mkEnableOption "fileserver";

    username = lib.mkOption {
      type = lib.types.str;
      default = "samba-user";
      example = "samba-user";
    };

    password = lib.mkOption {
      type = lib.types.str;
      example = "password123";
    };

    hosts_allow = lib.mkOption {
      type = lib.types.str;
      default = "192.168.1. 192.168.10. 192.168.100. 127.0.0.1 localhost";
      example = "192.168.1. 192.168.10. 192.168.100. 127.0.0.1 localhost";
    };

  };

  # Everything that should be done when/if the service is enabled
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      hdparm
      parted
      smartmontools
      snapraid

      # Custom packages
      (writeTextFile {
        name = "snapraid_1";
        text = ''
          This is a custom file created by Nix.
          It contains some sample contents.
        '';
        destination = "/mnt/Bank/snapraid.conf";
      })
    ];

    # Increase boot timeout
    #systemd.services."systemd-fsck@.service" = {
    #  environment = {
    #    SYSTEMD_FD_PATH = "/dev/null";
    #  };
    #  serviceConfig.TimeoutSec = "3min";
    #};

    #systemd.services."systemd-mount@.service" = {
    #  serviceConfig.TimeoutSec = "3min";
    #};

    #systemd.services."systemd-logind".serviceConfig.TimeoutSec = "3min";

    #############################
    # Setup samba server
    #############################
    # Frome here:
    #  https://nixos.wiki/wiki/Samba
    #  https://sourcegraph.com/github.com/Icy-Thought/snowflake/-/blob/modules/networking/samba.nix
    #  https://sourcegraph.com/github.com/wkennington/nixos/-/blob/nas/samba.nix

    # Create samba-user group
    users.groups.${cfg.username} = {
      gid = 2000;
    };

    # Create samba-user user
    users.users.${cfg.username} = {
      isSystemUser = true;
      description = "Residence of our Samba guest users";
      group = "${cfg.username}";
      home = "/var/empty";
      createHome = false;
      shell = pkgs.shadow;
      uid = 2000;  # Specify the desired UID for the user
    };

    # Create service
    services.samba = {
      enable = true;
      securityType = "user";
      openFirewall = true;
      extraConfig = ''
        workgroup = WORKGROUP
        server string = smbnix
        netbios name = smbnix
        security = user
        #use sendfile = yes
        #max protocol = smb2
        # note: localhost is the ipv6 localhost ::1
        hosts allow = ${cfg.hosts_allow}
        hosts deny = 0.0.0.0/0
        guest account = nobody
        map to guest = bad user
      '';
      shares = {
        SnapArrays_rw = {
          path = "/mnt/Bank/SnapArrays";
          browseable = "yes";
          "read only" = "no";
          "guest ok" = "no";
          "create mask" = "0644";
          "directory mask" = "0755";
          "force user" = cfg.username;
          "force group" = cfg.username;
        };
        SnapArrays_ro = {
          path = "/mnt/Bank/SnapArrays";
          browseable = "yes";
          "read only" = "yes";
          "guest ok" = "no";
          "create mask" = "0644";
          "directory mask" = "0755";
          "force user" = cfg.username;
          "force group" = cfg.username;
        };
      };
    };

    # Extra samba settings
    services.samba-wsdd = {
      enable = true;
      openFirewall = true;
    };

    # Automatically create the cfg.username smbpasswd login info
    system.activationScripts = {
      sambaUserSetup = {
        text = ''
           PATH=$PATH:${lib.makeBinPath [ pkgs.samba ]}
           export PASS="${cfg.password}"
           export LOGIN="${cfg.username}"
           echo -ne "$PASS\n$PASS\n" | smbpasswd -a -s $LOGIN
            '';
        deps = [ ];
      };
    };

    #############################
    # Setup NFS (untested)
    #############################
    services.nfs.server.enable = false;

    # Optionally, specify shared directories
    services.nfs.server.exports = ''
      /mnt/Bank/SnapArrays 192.168.10.0/24(rw,sync,no_subtree_check,anonuid=1000,anongid=1000,no_root_squash)
    '';

    networking.firewall.allowedTCPPorts = [ 2049 ];

  };
}
