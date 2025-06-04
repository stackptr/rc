# Web services and nginx configuration
{
  imports = [
    ./nginx-options.nix
    ./ssl-acme.nix
    ./nginx-config.nix
    ./virtual-hosts.nix
  ];
}
