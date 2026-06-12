{
  config,
  lib,
  username,
  ...
}:

lib.mkIf config.flags.profiles.interactive {
  home-manager.users.${username} = {
    programs.bat.enable = true;

    home.sessionVariables.BAT_PAGING = "never";
  };
}
