{
  config,
  lib,
  username,
  ...
}:

lib.mkIf config.flags.profiles.interactive {
  home-manager.users.${username}.programs.helix = {
    enable = true;

    settings = {
      theme = "onedarker";

      editor = {
        line-number = "relative";
        soft-wrap.enable = true;
      };
    };
  };
}
