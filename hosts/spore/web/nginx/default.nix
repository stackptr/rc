{
  config,
  pkgs,
  agenix,
  ...
}: {
  imports = [
    ./authelia-auth.nix
    ./authelia-proxy.nix
    ./nginx.nix
    ./irc.nix
  ];
}
