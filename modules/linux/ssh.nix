{ username, ... }:

{
  services.openssh = {
    enable = true;

    # Don't automatically open port 22.
    openFirewall = false;

    settings = {
      KbdInteractiveAuthentication = false;
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  home-manager.users.${username} = {
    programs.ssh.enable = true;
    services.ssh-agent.enable = true;
  };
}
