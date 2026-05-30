{ ... }:

{
  services.openssh = {
    enable = true;
    extraConfig = ''
      KbdInteractiveAuthentication no
      PasswordAuthentication no
      PermitRootLogin no
    '';
  };
}
