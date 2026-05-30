{ config, lib, ... }:

lib.mkMerge [
  {
    networking.hostName = config.hostname;
  }

  (lib.mkIf config.flags.network.networkManager {
    networking.networkmanager.enable = true;
  })

  (lib.mkIf config.flags.hardware.bluetooth {
    hardware.bluetooth.enable = true;
  })
]
