{ username, ... }:

{
  formFactor = "laptop";

  flags.profiles = {
    development = true;
    work = true;
  };

  home-manager.users.${username}.home.stateVersion = "25.05";

  system.stateVersion = 6;
}
