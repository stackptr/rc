# NixOS-specific configuration modules
{
  imports = [
    ./users.nix
    ./ssh.nix
    ./sudo.nix
  ];
}
