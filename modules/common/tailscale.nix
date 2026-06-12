{
  config,
  pkgs,
  lib,
  username,
  ...
}:

let
  inherit (config)
    flags
    hostname
    hosts
    ;
  inherit (lib.attrsets) attrValues genAttrs optionalAttrs;
  inherit (lib.lists) optionals remove;
  inherit (lib.trivial) flip;

  tailnetIdentityFile = "~/.ssh/id_ed25519_tailnet";

  # Use ghostty-bin in Darwin because we use the cask.
  ghosttyTerminfo = if flags.system.darwin then pkgs.ghostty-bin.terminfo else pkgs.ghostty.terminfo;

  peerHosts = remove hostname hosts;
  peerKeys =
    {
      acheron = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF3zteOi7/zlCxo1xKd63Tvwh2K2ZJ38eMdWu4SI1R9J";
      nile = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICWTxI3UJ03CCA0SqRSHNJmKULo0ApOQIPwzpUWWLKjy";
    }
    |> flip removeAttrs [ hostname ]
    |> attrValues;
in
{
  # Install Ghostty's terminfo on targets.
  environment.systemPackages = optionals flags.tailnet.ssh.target [ ghosttyTerminfo ];

  users.users.${username}.openssh.authorizedKeys.keys = optionals flags.tailnet.ssh.target peerKeys;

  home-manager.users.${username}.programs.ssh.settings =
    genAttrs peerHosts (host: {
      HostName = host;
      User = username;
      IdentityFile = tailnetIdentityFile;
      IdentitiesOnly = true;
    })
    |> optionalAttrs flags.tailnet.ssh.client;
}
