inputs @ {
  nixpkgs,
  agenix,
  home-manager,
  nix-darwin,
  nix-homebrew,
  homebrew-core,
  homebrew-cask,
  nix-index-database,
  direnv-instant,
  zx-dev,
  attic,
  disko,
  golink,
  ...
}: let
  overlays = import ./../overlays;

  mkHomeManager = {
    username,
    configDir,
    lightweight,
  }: let
    hostHomePath = ./../hosts/${configDir}/home.nix;
  in {
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.users.${username} = {...}: {
      imports =
        [
          nix-index-database.homeModules.nix-index
          direnv-instant.homeModules.direnv-instant
          ./../modules/home
          ./../home
        ]
        ++ nixpkgs.lib.optional (!lightweight) ./../home/full.nix
        ++ nixpkgs.lib.optional (builtins.pathExists hostHomePath) hostHomePath;
    };
    home-manager.extraSpecialArgs = {inherit inputs;};
  };

  mkNixosHost = {
    hostname,
    system,
    username,
    lightweight ? false,
    configDir ? hostname,
  }:
    nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {inherit inputs;};
      modules = [
        {
          rc.host.name = hostname;
          environment.systemPackages = [agenix.packages.${system}.default];
        }
        disko.nixosModules.disko
        ./../modules/base
        ./../modules/nixos
        ./../hosts/${configDir}
        agenix.nixosModules.default
        home-manager.nixosModules.home-manager
        (mkHomeManager {inherit username configDir lightweight;})
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
    configDir ? hostname,
  }: let
    system = "aarch64-darwin";
  in
    nix-darwin.lib.darwinSystem {
      inherit system;
      specialArgs = {inherit inputs;};
      modules = [
        {rc.host.name = hostname;}
        nix-homebrew.darwinModules.nix-homebrew
        ./../modules/base
        ./../modules/darwin
        ./../hosts/${configDir}
        agenix.darwinModules.default
        home-manager.darwinModules.home-manager
        (mkHomeManager {inherit username configDir lightweight;})
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
