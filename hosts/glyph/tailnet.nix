# Tailnet addresses of the devices glyph lets in to particular services
# (agents.nix's firewall, db.nix's pg_hba), from `tailscale ip <device>`;
# update them if a device re-registers
{
  spore = {
    v4 = "100.89.150.33";
    v6 = "fd7a:115c:a1e0::a033:9621";
  };
  # The iPhone, iPad and the Macs that run the Paseo app
  blip = {
    v4 = "100.71.241.100";
    v6 = "fd7a:115c:a1e0::1c33:f165";
  };
  slate = {
    v4 = "100.74.6.1";
    v6 = "fd7a:115c:a1e0::a33:601";
  };
  stroma = {
    v4 = "100.122.26.71";
    v6 = "fd7a:115c:a1e0::1133:1a48";
  };
  rhizome = {
    v4 = "100.89.6.21";
    v6 = "fd7a:115c:a1e0::7a33:615";
  };
}
