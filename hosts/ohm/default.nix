{ config, pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ./networking.nix # generated at runtime by nixos-infect
  ];

  boot.cleanTmpDir = true;
  zramSwap.enable = true;
  networking.hostName = "ohm";
  networking.domain = "";
  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICqvZ7US1q9NDUo15xyyzXCiAGXoes0tmETy/76+nG7A corey@x64.co'' ''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICt1ZqGf+/PV2hiuGVxbJvytEcKT0xvd4+iJZlFKtAQr corey@x64.co'' ];
}
