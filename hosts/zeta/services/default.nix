{
  config,
  pkgs,
  ...
}: {
  age.secrets.dd-agent.file = ./../secrets/dd-agent.age;
  services.openssh.enable = true;
  services.tailscale = {
    enable = true;
    extraUpFlags = ["--ssh"];
  };
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
  services.datadog-agent = {
    enable = true;
    hostname = "zeta";
    apiKeyFile = config.age.secrets.dd-agent.path;
    site = "us3.datadoghq.com";
    enableLiveProcessCollection = true;
  };

  programs.mosh.enable = true;
  programs.git.enable = true;
  programs.gnupg.agent.enable = true;
  programs.vim.defaultEditor = true;
  programs.zsh.enable = true;

  virtualisation.docker.enable = true;
  virtualisation.oci-containers.backend = "docker";
  virtualisation.oci-containers.containers = {
    portainer = import ./portainer.nix;
  };
}
