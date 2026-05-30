{
  config,
  lib,
  pkgs,
  ...
}:

{
  users.users."${config.username}" = {
    home = if pkgs.stdenv.isLinux then "/home/${config.username}" else "/Users/${config.username}";
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
