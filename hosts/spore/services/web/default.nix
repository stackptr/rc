# Web services and nginx configuration
{
  imports = [
    ./nginx-options.nix
    ./ssl-acme.nix
    ./nginx-config.nix
    ./srv.nix
    ./virtual-hosts.nix
  ];
}
