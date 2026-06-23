{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib.modules) mkIf;
in
mkIf config.flags.profiles.gaming {
  programs.steam.enable = true;

  environment.systemPackages = [
    pkgs.lutris

    (pkgs.retroarch.withCores (cores: [ cores.snes9x ]))
  ];
}
