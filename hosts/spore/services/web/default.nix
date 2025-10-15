# Web services and nginx configuration
{
  imports = [
    ./auth.nix
    ./ssl-acme.nix
    ./nginx-config.nix
    ./srv.nix
    ./virtual-hosts.nix
  ];
}
