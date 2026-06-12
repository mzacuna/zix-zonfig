{
  config,
  lib,
  pkgs,
  username,
  ...
}:

{
  users.users.${username} = {
    home = if pkgs.stdenv.isLinux then "/home/${username}" else "/Users/${username}";
  }
  // lib.optionalAttrs pkgs.stdenv.isLinux {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "bluetooth"
      "video"
    ]
    ++ lib.optionals config.flags.virtualisation.containers [ "podman" ];
  };
}
