{ config, lib, ... }:

lib.mkIf config.flags.profiles.interactive {
  home-manager.sharedModules = [
    {
      programs.helix = {
        enable = true;

        settings = {
          theme = "onedarker";
          editor = {
            line-number = "relative";
            soft-wrap.enable = true;
          };
        };
      };
    }
  ];
}
