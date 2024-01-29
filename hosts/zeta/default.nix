{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./system.nix
    ./wireless.nix
    ./services
  ];

  environment.systemPackages = with pkgs; [
    tailscale
  ];
  environment.pathsToLink = ["/share/zsh"];
}
