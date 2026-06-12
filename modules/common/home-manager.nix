{ config, username, ... }:

{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit username; };

    # Rename pre-existing files instead of failing activation when home-manager
    # wants to manage a path that already exists.
    backupFileExtension = "backup";

    users.${username}.home.homeDirectory = config.users.users.${username}.home;
  };
}
