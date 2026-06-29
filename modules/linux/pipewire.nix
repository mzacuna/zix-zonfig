{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib.meta) getExe';
in
lib.mkIf config.flags.profiles.graphical {
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  systemd.user.services.g435-playback-volume = lib.mkIf (config.hostname == "acheron") {
    description = "Set Logitech G435 hardware playback volume";
    after = [
      "pipewire.service"
      "wireplumber.service"
    ];
    wantedBy = [ "default.target" ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${getExe' pkgs.alsa-utils "amixer"} -c Headset sset 'G435 Wireless Gaming Headset Playback Volum' 175";
      Restart = "on-failure";
      RestartSec = "2s";
    };
  };
}
