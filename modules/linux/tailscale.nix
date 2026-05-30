{
  services.tailscale = {
    enable = true;

    # Opens only Tailscale's UDP transport port, 41641 by default, on the
    # regular NixOS firewall. This helps peers make direct WireGuard
    # connections instead of falling back to DERP relays.
    openFirewall = true;
  };

  # Tailscale's default Linux firewall mode accepts tailnet traffic itself.
  # Enforce tailnet reachability in Tailscale Access controls; keep this as
  # local documentation and defense-in-depth for normal OpenSSH.
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22 ];
}
