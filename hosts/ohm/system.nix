{ config, pkgs, ... }: {
  users = {
    mutableUsers = false;
    users.mu = {
      isNormalUser = true;
      extraGroups = [ "wheel"];
      shell = pkgs.zsh;
    };
  };
  users.users.root.openssh.authorizedKeys.keys = [''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICqvZ7US1q9NDUo15xyyzXCiAGXoes0tmETy/76+nG7A corey@x64.co'' ''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICt1ZqGf+/PV2hiuGVxbJvytEcKT0xvd4+iJZlFKtAQr corey@x64.co'' ];
  users.users.mu.openssh.authorizedKeys.keys = [''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICqvZ7US1q9NDUo15xyyzXCiAGXoes0tmETy/76+nG7A corey@x64.co'' ''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICt1ZqGf+/PV2hiuGVxbJvytEcKT0xvd4+iJZlFKtAQr corey@x64.co'' ];

  system.stateVersion = "24.05";
}
