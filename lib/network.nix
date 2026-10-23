# How hosts are reachable from outside the tailnet, for docs/ports.md
# (lib/ports.nix).
{
  # Hosts with a public address, so their firewall's allow lists are open to
  # the internet. The rest sit behind the router's NAT at home.
  public = ["spore"];

  # Port forwards on the eero router: set in the eero app, copied here by
  # hand. Home has no global IPv6 (only ULA prefixes), so the IPv6 side of a
  # forward currently reaches nothing.
  forwards = [
    {
      host = "glyph";
      port = 53150;
      protocols = ["tcp" "udp"];
      families = ["IPv4" "IPv6"];
      description = "Transmission peer port";
    }
  ];
}
