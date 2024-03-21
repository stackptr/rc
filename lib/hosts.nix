{
  self,
  nixpkgs,
  agenix,
  home-manager,
  nix-darwin,
  nix-homebrew,
  homebrew-bundle,
  homebrew-core,
  homebrew-cask,
  profile,
  disko,
  ...
}: let
  keys = import ./keys.nix;
  baseHomeManager = username: {
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.users.${username} = import ./../home;
  };
  nixosHomeManager = baseHomeManager "mu";
  nixosHost = {
    system,
    hostname,
  }:
    nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit profile keys;
      };
      modules = [
        {environment.systemPackages = [agenix.packages.${system}.default];}
        disko.nixosModules.disko
        ./../modules/base.nix
        ./../modules/nixos.nix
        ./../hosts/${hostname}
        agenix.nixosModules.default
        home-manager.nixosModules.home-manager
        nixosHomeManager
      ];
    };
  darwinHomeManager = baseHomeManager "corey";
  darwinHost = {hostname, ...}:
    nix-darwin.lib.darwinSystem {
      specialArgs = {inherit self keys;};
      modules = [
        nix-homebrew.darwinModules.nix-homebrew
        ./../modules/base.nix
        ./../modules/darwin.nix
        ./../hosts/${hostname}
        home-manager.darwinModules.home-manager
        darwinHomeManager
        {
          nix-homebrew = {
            enable = true;
            enableRosetta = false;
            user = "corey";
            taps = {
              "homebrew/homebrew-bundle" = homebrew-bundle;
              "homebrew/homebrew-core" = homebrew-core;
              "homebrew/homebrew-cask" = homebrew-cask;
            };
            mutableTaps = false;
          };
        }
      ];
    };
  mkHosts = f: hostEntries:
    builtins.listToAttrs (map
      (host: {
        name = host.hostname;
        value = f host;
      })
      hostEntries);
  hostEntry = name: {hostname = name;};
in {
  mkNixosHosts = mkHosts nixosHost;
  mkDarwinHosts = names: mkHosts darwinHost (map hostEntry names);
}
