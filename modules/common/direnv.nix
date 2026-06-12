{
  config,
  lib,
  username,
  ...
}:

lib.mkIf config.flags.profiles.interactive {
  home-manager.users.${username}.programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
