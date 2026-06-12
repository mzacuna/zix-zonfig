{ config, username, ... }:

{
  imports = [ ./hardware.nix ];

  formFactor = "desktop";

  flags.profiles.gaming = true;

  gpu = "nvidia";

  home-manager.users.${username}.home.stateVersion = config.system.stateVersion;

  system.stateVersion = "25.05";
}
