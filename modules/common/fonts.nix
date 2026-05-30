{
  config,
  pkgs,
  lib,
  ...
}:

lib.mkIf config.flags.profiles.graphical {
  home-manager.sharedModules = [
    {
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
    }

    (lib.mkIf config.flags.system.linux { fonts.fontconfig.enable = true; })
  ];
}
