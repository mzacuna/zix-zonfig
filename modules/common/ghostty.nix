{
  config,
  pkgs,
  lib,
  ...
}:

lib.mkIf config.flags.profiles.graphical {
  home-manager.sharedModules = [
    {
      programs.ghostty = {
        enable = true;
        package = lib.mkIf config.flags.system.darwin null;
        settings = {
          command = "${pkgs.fish}/bin/fish";
          font-family = "Inconsolata Nerd Font";
          font-size = 22;
          theme = "Carbonfox";
          background-opacity = 0.93;
          background-blur = config.flags.system.darwin;
          window-padding-x = 8;
        };
      };
    }
  ];
}
