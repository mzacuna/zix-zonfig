{
  config,
  lib,
  username,
  ...
}:

lib.mkIf config.flags.profiles.graphical {
  home-manager.users.${username}.xdg.userDirs = {
    enable = true;
    setSessionVariables = false;
  };
}
