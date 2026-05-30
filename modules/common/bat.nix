{ config, lib, ... }:

lib.mkIf config.flags.profiles.interactive {
  home-manager.sharedModules = [
    {
      home.sessionVariables.BAT_PAGING = "never";
      programs.bat.enable = true;
    }
  ];
}
