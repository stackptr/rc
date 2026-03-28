inputs @ {
  self,
  nixpkgs,
  nixpkgs-stable-25-11,
  nixpkgs-stable-24-05,
  agenix,
  home-manager,
  nix-darwin,
  nix-homebrew,
  homebrew-core,
  homebrew-cask,
  llm-profile,
  nix-index-database,
  zx-dev,
  attic,
  disko,
  golink,
  ...
}: let
  keys = import ./keys.nix;
  overlays = import ./../overlays;

  mkHomeManager = {
    username,
    hostname,
    system,
    showBatteryStatus,
    lightweight ? false,
  }: let
    pkgs-stable-25-11 = import nixpkgs-stable-25-11 {inherit system;};
    pkgs-stable-24-05 = import nixpkgs-stable-24-05 {inherit system;};
    hostHomePath = ./../hosts/${hostname}/home.nix;
    hostHomeConfig =
      if builtins.pathExists hostHomePath
      then hostHomePath
      else null;
  in {
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.users.${username} = {...}: {
      imports =
        [
          nix-index-database.homeModules.nix-index
          agenix.homeManagerModules.default
          ./../modules/home
          ./../home
        ]
        ++ nixpkgs.lib.optionals (hostHomeConfig != null) [hostHomeConfig];
    };
    home-manager.extraSpecialArgs = {
      inherit hostname lightweight llm-profile pkgs-stable-25-11 pkgs-stable-24-05 showBatteryStatus;
    };
  };

  mkNixosHost = {
    hostname,
    system,
    username,
    lightweight ? false,
  }:
    nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit inputs keys username hostname;
        pkgs-stable-25-11 = import nixpkgs-stable-25-11 {inherit system;};
        pkgs-stable-24-05 = import nixpkgs-stable-24-05 {inherit system;};
      };
      modules = [
        {environment.systemPackages = [agenix.packages.${system}.default];}
        disko.nixosModules.disko
        ./../modules/base
        ./../modules/nixos
        ./../hosts/${hostname}
        agenix.nixosModules.default
        home-manager.nixosModules.home-manager
        (mkHomeManager {
          inherit username hostname system lightweight;
          showBatteryStatus = false;
        })
        {
          nixpkgs.overlays = overlays;
        }
        attic.nixosModules.atticd
        golink.nixosModules.default
        zx-dev.nixosModules.default
      ];
    };

  mkDarwinHost = {
    hostname,
    username,
    lightweight ? false,
  }: let
    system = "aarch64-darwin";
  in
    nix-darwin.lib.darwinSystem {
      inherit system;
      specialArgs = {
        inherit inputs self keys username hostname;
        pkgs-stable-25-11 = import nixpkgs-stable-25-11 {inherit system;};
        pkgs-stable-24-05 = import nixpkgs-stable-24-05 {inherit system;};
        nixDarwin = nix-darwin;
      };
      modules = [
        nix-homebrew.darwinModules.nix-homebrew
        ./../modules/base
        ./../modules/darwin
        ./../hosts/${hostname}
        home-manager.darwinModules.home-manager
        (mkHomeManager {
          inherit username hostname system lightweight;
          showBatteryStatus = true;
        })
        {
          nix-homebrew = {
            enable = true;
            enableRosetta = false;
            user = username;
            taps = {
              "homebrew/homebrew-core" = homebrew-core;
              "homebrew/homebrew-cask" = homebrew-cask;
            };
            mutableTaps = false;
          };
        }
        {
          nixpkgs.overlays = overlays;
        }
      ];
    };
in {
  inherit mkNixosHost mkDarwinHost;
}
