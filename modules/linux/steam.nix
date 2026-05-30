{ config, lib, ... }:

lib.mkIf config.flags.profiles.gaming {
  programs.steam.enable = true;
}
