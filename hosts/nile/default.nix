{ config, ... }:

{
  username = "martin";
  hostname = "nile";

  formFactor = "laptop";
  isDev = true;
  isWork = true;

  home-manager.users."${config.username}".home = {
    stateVersion = "25.05";
    homeDirectory = config.users.users."${config.username}".home;
  };

  system.stateVersion = 6;
}
