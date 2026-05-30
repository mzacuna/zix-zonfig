{ config, lib, ... }:

lib.mkIf config.flags.virtualisation.containers {
  virtualisation.containers.enable = true;

  virtualisation = {
    podman = {
      enable = true;
    };
  };
}
