{
  config,
  pkgs,
  lib,
  ...
}:

lib.mkIf config.flags.profiles.graphical {
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  services.desktopManager.plasma6.enable = true;

  environment.plasma6.excludePackages = [
    pkgs.kdePackages.kate
    pkgs.kdePackages.konsole
    pkgs.kdePackages.khelpcenter
    pkgs.kdePackages.krdp
  ];
}
