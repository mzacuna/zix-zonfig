{ config, lib, ... }:

lib.mkIf config.isGaming {
  programs.steam.enable = true;
}
