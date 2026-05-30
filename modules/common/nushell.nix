{ config, lib, ... }:

lib.mkIf config.flags.profiles.interactive {
  home-manager.sharedModules = [
    {
      programs.nushell = {
        enable = true;
        configFile.source = ./config.nu;
      };
    }
  ];
}
