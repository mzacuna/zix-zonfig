{ config, username, ... }:

{
  imports = [
    ./hardware.nix
    ./diagnosis.nix
  ];

  formFactor = "laptop";

  flags = {
    profiles = {
      development = false;
      graphical = false;
      interactive = false;
      work = false;
    };

    tailnet.ssh = {
      client = false;
      target = true;
    };

    network.networkManager = true;

    virtualisation.containers = true;
  };

  gpu = "amd";

  home-manager.users.${username}.home.stateVersion = config.system.stateVersion;

  system.stateVersion = "24.11";
}
