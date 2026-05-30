{ config, lib, ... }:

lib.mkIf (config.flags.profiles.graphical && config.gpu == "nvidia") {
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.open = true;
}
