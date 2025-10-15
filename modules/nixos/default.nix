# NixOS-specific configuration modules
{
  imports = [
    ./web
    ./users.nix
    ./ssh.nix
    ./sudo.nix
  ];
}
