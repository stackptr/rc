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
  profile,
  disko,
  ...
}: let
  keys = import ./keys.nix;
  baseHomeManager = {
    username,
    pkgs-stable,
    hostname,
    enableGuiPackages,
    ...
  }: {
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.users.${username} = import ./../home;
    home-manager.extraSpecialArgs = {
      inherit pkgs-stable hostname enableGuiPackages;
    };
  };
  nixosHost = {
    system,
    hostname,
    allowVpn,
  }: let
    username = "mu";
  in
    nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit profile keys username hostname allowVpn;
        pkgs-stable = import nixpkgs-stable {
          inherit system;
        };
        enableGuiPackages = false;
      };
      modules = [
        {environment.systemPackages = [agenix.packages.${system}.default];}
        disko.nixosModules.disko
        ./../modules/base.nix
        ./../modules/nixos.nix
        ./../hosts/${hostname}
        agenix.nixosModules.default
        home-manager.nixosModules.home-manager
        baseHomeManager
      ];
    };
  darwinHost = {
    hostname,
    allowVpn,
    ...
  }: let
    username = "corey";
    system = "aarch64-darwin";
  in
    nix-darwin.lib.darwinSystem {
      inherit system;
      specialArgs = {
        inherit self keys username hostname allowVpn;
        pkgs-stable = import nixpkgs-stable {
          inherit system;
        };
        enableGuiPackages = true;
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
in {
  mkNixosHosts = mkHosts nixosHost;
  mkDarwinHosts = mkHosts darwinHost;
}
