{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./networking.nix # generated at runtime by nixos-infect
    ./containers.nix
  ];

  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;
  networking.hostName = "ohm";
  networking.domain = "";
  security.pam.sshAgentAuth.enable = true;

  services.openssh.enable = true;
  services.tailscale.enable = true;
  services.do-agent.enable = true;

  networking.firewall.allowedTCPPorts = [80 443];

  system.stateVersion = "23.11";
}
