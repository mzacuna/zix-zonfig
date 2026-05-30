{ config, lib, ... }:

lib.mkIf config.flags.profiles.graphical {
  programs.dconf.enable = true;

  home-manager.sharedModules = [
    {
      dconf.settings = {
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
          icon-theme = "Papirus-Dark";
        };
      };
    }
  ];
}
