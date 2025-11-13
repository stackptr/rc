# NixOS-specific configuration modules
{
  imports = [
    ./web
    ./filebrowser-quantum.nix
    ./users.nix
    ./ssh.nix
    ./sudo.nix
  ];
}
