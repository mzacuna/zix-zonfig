{ config, ... }:

{
  imports = [
    ./hardware.nix
    ./diagnosis.nix
  ];

  username = "martin";
  hostname = "tigris";

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

  home-manager.users."${config.username}".home = {
    inherit (config.system) stateVersion;
    homeDirectory = config.users.users."${config.username}".home;
  };

  system.stateVersion = "24.11";
}
