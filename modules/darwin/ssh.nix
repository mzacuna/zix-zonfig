{ config, lib, ... }:

let
  inherit (lib.strings) concatStringsSep;

  terminfoDirs = [
    "${config.system.path}/share/terminfo"
    "/usr/share/terminfo"
  ];
in
{
  services.openssh = {
    enable = true;

    extraConfig = ''
      # zsh initializes terminfo before nix-darwin's /etc/zshenv finishes.
      # Put Nix and macOS terminfo in sshd's child environment so TERM is known
      # as soon as the login shell starts.
      SetEnv TERMINFO_DIRS=${concatStringsSep ":" terminfoDirs}

      KbdInteractiveAuthentication no
      PasswordAuthentication no
      PermitRootLogin no
    '';
  };
}
