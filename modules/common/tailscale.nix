{ config, lib, ... }:

let
  inherit (config) hostname username;

  tailnetIdentityFile = "~/.ssh/id_ed25519_tailnet";

  tailnetHosts = [
    "acheron"
    "nile"
    "tigris"
  ];

  tailnetUserKeys = {
    acheron = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF3zteOi7/zlCxo1xKd63Tvwh2K2ZJ38eMdWu4SI1R9J";
    nile = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICWTxI3UJ03CCA0SqRSHNJmKULo0ApOQIPwzpUWWLKjy";
  };

  peerHosts = lib.remove hostname tailnetHosts;
  peerUserKeys = lib.attrValues (removeAttrs tailnetUserKeys [ hostname ]);
in
{
  users.users.${username}.openssh.authorizedKeys.keys =
    lib.optionals config.flags.tailnet.ssh.target peerUserKeys;

  home-manager.sharedModules = [
    {
      programs.ssh.matchBlocks = lib.optionalAttrs config.flags.tailnet.ssh.client (
        lib.genAttrs peerHosts (host: {
          hostname = host;
          user = username;
          identityFile = tailnetIdentityFile;
          identitiesOnly = true;
        })
      );
    }
  ];
}
