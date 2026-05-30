{ config, lib, ... }:

lib.mkIf config.flags.profiles.graphical {
  home-manager.sharedModules = [
    {
      xdg.userDirs = {
        enable = true;
        setSessionVariables = false;
      };
    }
  ];
}
