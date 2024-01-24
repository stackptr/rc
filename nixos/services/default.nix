{ config, pkgs, ... }: {
  services.openssh.enable = true;
  services.tailscale.enable = true;
  services.samba = {
    enable = true;
    securityType = "user";
    openFirewall = true;
    invalidUsers = [];
    shares = {
      zeta = {
        path = "/";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "root";
        "force group" = "root";
      };
    };
  };

  programs.mosh.enable = true;
  programs.git = {
    enable = true;
    config = {
      user = {
        name = "✿ corey";
        email = "corey@x64.co";
      };
    };
  };
  programs.vim.defaultEditor = true;
  programs.zsh.enable = true;

  virtualisation.docker.enable = true;
  virtualisation.oci-containers.backend = "docker";
  virtualisation.oci-containers.containers = {
    portainer = import ./portainer.nix;
  };
}
