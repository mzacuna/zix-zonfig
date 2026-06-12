{ username, ... }:

{
  home-manager.users.${username}.programs.ssh = {
    enable = true;

    enableDefaultConfig = false;

    settings = {
      "*" = {
        ForwardAgent = false;
        AddKeysToAgent = "yes";
        Compression = false;

        ServerAliveInterval = 60;
        ServerAliveCountMax = 3;

        HashKnownHosts = false;
        UserKnownHostsFile = "~/.ssh/known_hosts";

        ControlMaster = "auto";
        ControlPath = "~/.ssh/master-%r@%n:%p";
        ControlPersist = "10m";
      };

      "github.com" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519_github";
      };
    };
  };
}
