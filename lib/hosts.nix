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
  mac-app-util,
  profile,
  disko,
  golink,
  ...
}: let
  keys = import ./keys.nix;
  overlays = [
    (import ./../overlays/gitify.nix)
    (import ./../overlays/repo-packages.nix)
    (import ./../overlays/whatsapp-for-mac.nix)
  ];
  baseHomeManager = {
    username,
    pkgs-stable,
    enableGuiPackages,
    hostHomeConfig ? null,
    ...
  }: {
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.users.${username} =
      if hostHomeConfig != null
      then
        {...}: {
          imports = [
            (import ./../home)
            hostHomeConfig
          ];
        }
      else import ./../home;
    home-manager.extraSpecialArgs = {
      inherit pkgs-stable enableGuiPackages;
    };
  };
  nixosHost = {
    system,
    hostname,
    allowVpn,
  }: let
    username = "mu";
    enableGuiPackages = false;
    hostHomePath = ./../hosts/${hostname}/home.nix;
    hostHomeConfig =
      if builtins.pathExists hostHomePath
      then hostHomePath
      else null;
  in
    nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit profile keys username hostname allowVpn;
        pkgs-stable = import nixpkgs-stable {
          inherit system;
        };
      };
      modules = [
        {environment.systemPackages = [agenix.packages.${system}.default];}
        disko.nixosModules.disko
        ./../modules/base.nix
        ./../modules/nixos.nix
        ./../hosts/${hostname}
        agenix.nixosModules.default
        home-manager.nixosModules.home-manager
        (baseHomeManager {
          inherit username enableGuiPackages hostHomeConfig;
          pkgs-stable = import nixpkgs-stable {inherit system;};
        })
        {
          nixpkgs.overlays = overlays;
        }
        golink.nixosModules.default
      ];
    };
  darwinHost = {
    hostname,
    allowVpn,
    ...
  }: let
    username = "corey";
    system = "aarch64-darwin";
    enableGuiPackages = true;
    hostHomePath = ./../hosts/${hostname}/home.nix;
    hostHomeConfig =
      if builtins.pathExists hostHomePath
      then hostHomePath
      else null;
  in
    nix-darwin.lib.darwinSystem {
      inherit system;
      specialArgs = {
        inherit self keys username hostname allowVpn;
        pkgs-stable = import nixpkgs-stable {
          inherit system;
        };
        nixDarwin = nix-darwin;
      };
      modules = [
        nix-homebrew.darwinModules.nix-homebrew
        mac-app-util.darwinModules.default
        ./../modules/base.nix
        ./../modules/darwin
        ./../hosts/${hostname}
        home-manager.darwinModules.home-manager
        (baseHomeManager {
          inherit username enableGuiPackages hostHomeConfig;
          pkgs-stable = import nixpkgs-stable {inherit system;};
        })
        {
          home-manager.sharedModules = [
            mac-app-util.homeManagerModules.default
          ];
        }
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
        {
          nixpkgs.overlays = overlays;
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
