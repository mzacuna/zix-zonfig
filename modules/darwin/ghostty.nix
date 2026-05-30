{ config, lib, ... }:

lib.mkIf config.flags.profiles.graphical {
  homebrew.casks = [ "ghostty" ];
}
