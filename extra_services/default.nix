{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./cloud_init.nix
    ./desktop_apps.nix
    ./fileserver.nix
    ./glances_service.nix
    ./gpu.nix
    ./gow_wolf.nix
    ./home_manager.nix
    ./mount_smb_shares.nix
    ./single_node_kube.nix
  ];
}
