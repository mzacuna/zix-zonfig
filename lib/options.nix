{
  config,
  pkgs,
  lib,
  ...
}:
let
  mkDerived =
    conditional: description:
    lib.mkOption {
      type = lib.types.bool;
      default = conditional;
      description = description;
      readOnly = true;
    };
  mkEnum =
    variants:
    lib.mkOption {
      type = lib.types.nullOr (lib.types.enum variants);
      default = null;
    };
in
{
  options = {
    formFactor = lib.mkOption {
      type = lib.types.enum [
        "desktop"
        "laptop"
        "server"
      ];
    };
    isPC = mkDerived (config.formFactor != "server") "Personal computer (non-server) configuration";

    isLinux = mkDerived pkgs.stdenv.hostPlatform.isLinux "Linux configuration";
    isDarwin = mkDerived pkgs.stdenv.hostPlatform.isDarwin "Darwin configuration";

    isDev = lib.mkEnableOption "developer configuration";
    isWork = lib.mkEnableOption "work configuration";
    isGaming = lib.mkEnableOption "gaming configuration";

    username = lib.mkOption { type = lib.types.str; };
    hostname = lib.mkOption { type = lib.types.str; };

    gpu = mkEnum [
      "nvidia"
      "amd"
      "intel"
    ];
  };
}
