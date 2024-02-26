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

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
    port = 5432;
    ensureUsers = [
      {
        name = "mastodon";
        ensureDBOwnership = true;
      }
    ];
    ensureDatabases = ["mastodon"];
    authentication = pkgs.lib.mkOverride 10 ''
      # Any user can connect to any database via Unix socket or local loopback
      local  all   all                  trust
      host   all   all   127.0.0.1/32   trust
    '';
  };
  services.postgresqlBackup = {
    enable = true;
    databases = ["mastodon"];
  };
  services.redis.servers.mastodon = {
    enable = true;
    port = 31637;
  };

  networking.firewall.allowedTCPPorts = [80 443];

  system.stateVersion = "23.11";
}
