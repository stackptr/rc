{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./../../../../modules/services/mautrix-discord.nix
    ./dendrite.nix
    ./heisenbridge.nix
    ./discord.nix
  ];
  
  nixpkgs.config.permittedInsecurePackages = [
    "olm-3.2.16" # TODO: https://github.com/NixOS/nixpkgs/pull/334638#issuecomment-2289025802
  ];
}
