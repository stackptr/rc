{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./system.nix
    ./hardware-configuration.nix
    ./networking.nix # generated at runtime by nixos-infect
    ./containers.nix
  ];

  boot.cleanTmpDir = true;
  zramSwap.enable = true;
  networking.hostName = "ohm";
  networking.domain = "";
  security.pam.sshAgentAuth.enable = true;

  programs.zsh.enable = true;
  services.openssh.enable = true;
  services.tailscale.enable = true;
}
