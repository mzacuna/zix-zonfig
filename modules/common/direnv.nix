{ config, lib, ... }:

lib.mkIf config.flags.profiles.interactive {
  home-manager.sharedModules = [
    {
      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
      };
    }
  ];
}
