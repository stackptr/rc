{
  self,
  nixpkgs,
  nixpkgs-stable,
  agenix,
  home-manager,
  nix-darwin,
  nix-homebrew,
  homebrew-bundle,
  homebrew-core,
  homebrew-cask,
  homebrew-wine,
  profile,
  ...
}: let
  keys = import ./keys.nix;
  baseHomeManager = {
    username,
    pkgs-stable,
    ...
  }: {
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.users.${username} = import ./../home;
    home-manager.extraSpecialArgs = {
      inherit pkgs-stable;
    };
  };
  nixosHost = {
    system,
    hostname,
  }: let
    username = "mu";
  in
    nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit profile keys username;
        pkgs-stable = import nixpkgs-stable {
          inherit system;
        };
      };
      modules = [
        {environment.systemPackages = [agenix.packages.${system}.default];}
        ./../modules/base.nix
        ./../modules/nixos.nix
        ./../hosts/${hostname}
        agenix.nixosModules.default
        home-manager.nixosModules.home-manager
        baseHomeManager
      ];
    };
  darwinHost = {hostname, ...}: let
    username = "corey";
    system = "aarch64-darwin";
  in
    nix-darwin.lib.darwinSystem {
      inherit system;
      specialArgs = {
        inherit self keys username;
        pkgs-stable = import nixpkgs-stable {
          inherit system;
        };
      };
      modules = [
        nix-homebrew.darwinModules.nix-homebrew
        ./../modules/base.nix
        ./../modules/darwin.nix
        ./../hosts/${hostname}
        home-manager.darwinModules.home-manager
        baseHomeManager
        {
          nix-homebrew = {
            enable = true;
            enableRosetta = false;
            user = username;
            taps = {
              "homebrew/homebrew-bundle" = homebrew-bundle;
              "homebrew/homebrew-core" = homebrew-core;
              "homebrew/homebrew-cask" = homebrew-cask;
              "gcenx/homebrew-wine" = homebrew-wine;
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
