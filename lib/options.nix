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
  mkFlag =
    default: description:
    lib.mkOption {
      type = lib.types.bool;
      default = default;
      description = description;
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

    username = lib.mkOption { type = lib.types.str; };
    hostname = lib.mkOption { type = lib.types.str; };

    gpu = mkEnum [
      "nvidia"
      "amd"
      "intel"
    ];

    flags = {
      system = {
        linux = mkDerived pkgs.stdenv.hostPlatform.isLinux "Linux configuration";
        darwin = mkDerived pkgs.stdenv.hostPlatform.isDarwin "Darwin configuration";
      };

      profiles = {
        interactive = mkFlag (config.formFactor != "server") "interactive user environment";
        graphical = mkFlag config.flags.profiles.interactive "graphical user environment";
        development = mkFlag false "developer configuration";
        work = mkFlag false "work configuration";
        gaming = mkFlag false "gaming configuration";
      };

      hardware.bluetooth = mkFlag config.flags.profiles.graphical "Bluetooth support";

      network.networkManager = mkFlag config.flags.profiles.graphical "NetworkManager networking";

      virtualisation.containers = mkFlag (
        config.flags.profiles.development || config.flags.profiles.work
      ) "Podman/OCI container support";

      tailnet.ssh = {
        client = mkFlag config.flags.profiles.interactive "can initiate SSH to tailnet hosts";
        target = mkFlag true "accepts SSH from tailnet hosts";
      };
    };
  };
}
