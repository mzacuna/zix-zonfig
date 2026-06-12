{
  config,
  lib,
  username,
  ...
}:

lib.mkIf config.flags.profiles.interactive {
  home-manager.users.${username}.programs.nushell = {
    enable = true;
    configFile.source = ./config.nu;
  };
}
