# NixOS-specific configuration modules
{
  imports = [
    ./llm
    ./web
    ./filebrowser-quantum.nix
    ./users.nix
    ./ssh.nix
    ./sudo.nix
  ];
}
