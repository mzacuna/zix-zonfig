{
  config,
  lib,
  username,
  ...
}:

# Fish is enabled at both layers on purpose:
# - System level: needed on macOS, otherwise fish in Ghostty doesn't see any
#   Nix paths on PATH.
# - HM level: home-manager's fish integrations (direnv, starship, aliases)
#   only land in ~/.config/fish/config.fish when HM's fish is enabled.
lib.mkIf config.flags.profiles.interactive {
  programs.fish = {
    enable = true;

    interactiveShellInit = ''
      set fish_greeting # Disable greeting
    '';
  };

  home-manager.users.${username}.programs.fish.enable = true;
}
