{
  config,
  pkgs,
  lib,
  username,
  ...
}:

lib.mkIf config.flags.profiles.graphical {
  home-manager.users.${username} = {
    home.packages = [
      pkgs.noto-fonts
      pkgs.noto-fonts-cjk-sans
      pkgs.noto-fonts-color-emoji
      pkgs.aporetic
      pkgs.nerd-fonts.inconsolata
      pkgs.nerd-fonts.jetbrains-mono
      pkgs.intel-one-mono
      pkgs.inter
    ];

    fonts.fontconfig.enable = lib.mkIf config.flags.system.linux true;
  };
}
