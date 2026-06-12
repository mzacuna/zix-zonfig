{
  config,
  lib,
  username,
  ...
}:

lib.mkIf config.flags.profiles.graphical {
  programs.dconf.enable = true;

  home-manager.users.${username}.dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      icon-theme = "Papirus-Dark";
    };
  };
}
