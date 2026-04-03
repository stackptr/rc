{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./alloy.nix
    ./attic.nix
    ./db.nix
    ./avahi.nix
    ./dns.nix
    ./filebrowser.nix
    ./jellyfin.nix
    ./loki.nix
    ./n8n.nix
    ./nfs.nix
    ./open-terminal.nix
    ./open-webui.nix
    ./prometheus.nix
    ./samba.nix
    ./torrents.nix
  ];
  users.groups.media = {};
  users.users.mu.extraGroups = ["media"];
  users.users.${config.services.transmission.user}.extraGroups = ["media"];

  services.openssh.enable = true;
  services.roon-server = {
    enable = true;
    openFirewall = true;
  };
  networking.firewall = {
    allowedTCPPorts = [
      554 # AirPlay streaming
      3689 # Digital Audio Access Protocol (DAAP)
      55002 # Roon ARC
    ];
    allowedUDPPorts = [
      554
      1900 # ssdp / Bonjour
    ];
    allowedUDPPortRanges = [
      # Apple Airplay
      {
        from = 6001;
        to = 6002;
      }
      # Bonjour
      {
        from = 5350;
        to = 5353;
      }
      # Chromecast and Apple Airplay
      {
        from = 32768;
        to = 65535;
      }
    ];
    # Dynamically allocated ports for Roon Bridge opened for local network
    extraCommands = ''
      iptables -A nixos-fw -p tcp --dport 30000:65535 -s 192.168.4.0/24 -j nixos-fw-accept
      iptables -A nixos-fw -p udp --dport 30000:65535 -s 192.168.4.0/24 -j nixos-fw-accept
    '';
  };
  services.tailscale = {
    enable = true;
    extraUpFlags = ["--ssh"];
  };

  age.secrets.kagi-api-key = {
    file = ./../secrets/kagi-api-key.age;
    mode = "440";
    owner = "kagi-mcp";
    group = "kagi-mcp";
  };

  age.secrets.context7-api-key = {
    file = ./../secrets/context7-api-key.age;
    mode = "440";
  };

  age.secrets.grafana-mcp-token = {
    file = ./../secrets/grafana-mcp-token.age;
    mode = "440";
    owner = "grafana-mcp";
    group = "grafana-mcp";
  };

  age.secrets.graphite-auth-token = {
    file = ./../secrets/graphite-auth-token.age;
    mode = "440";
    owner = "graphite-mcp";
    group = "graphite-mcp";
  };

  services.basic-memory.enable = true;
  rc.backup = {
    enable = true;
    paths = [
      config.services.postgresqlBackup.location
      "/var/lib/basic-memory"
      "/var/lib/open-webui"
      "/var/lib/roon-server/backup"
    ];
  };
  services.mcp-nixos.enable = true;
  services.kagi-mcp = {
    enable = true;
    environmentFile = config.age.secrets.kagi-api-key.path;
  };
  services.grafana-mcp = {
    enable = true;
    grafanaUrl = "https://grafana.zx.dev";
    tokenFile = config.age.secrets.grafana-mcp-token.path;
  };
  services.graphite-mcp = {
    enable = true;
    authTokenFile = config.age.secrets.graphite-auth-token.path;
  };
  services.mcpjungle = {
    enable = true;
    servers.basic-memory = {
      url = "http://127.0.0.1:8091/mcp";
      description = "Knowledge management with markdown files";
    };
    servers.mcp-nixos = {
      url = "http://127.0.0.1:8092/mcp";
      description = "NixOS options, packages, and Home Manager search";
    };
    servers.kagi = {
      url = "http://127.0.0.1:8093/mcp";
      description = "Kagi web search and page summarization";
    };
    servers.grafana = {
      url = "http://127.0.0.1:8095/mcp";
      description = "Grafana dashboards, Loki logs, and Prometheus metrics";
    };
    servers.graphite = {
      url = "http://127.0.0.1:8094/mcp";
      description = "Graphite CLI for stacked PRs and code review";
    };
    servers.context7 = {
      url = "https://mcp.context7.com/mcp";
      description = "Up-to-date library documentation and code examples";
      headers.CONTEXT7_API_KEY = "$CONTEXT7_API_KEY";
      environmentFile = config.age.secrets.context7-api-key.path;
    };
    servers.deepwiki = {
      url = "https://mcp.deepwiki.com/mcp";
      description = "AI-powered documentation and Q&A for GitHub repositories";
    };
    servers.aws-knowledge = {
      url = "https://knowledge-mcp.global.api.aws";
      description = "AWS documentation and development reference";
    };
    servers.cloudflare-docs = {
      url = "https://docs.mcp.cloudflare.com/sse";
      description = "Cloudflare documentation and API reference";
    };
    servers.semgrep = {
      url = "https://mcp.semgrep.ai/mcp";
      description = "Code security scanning for vulnerabilities, supply chain, and secrets";
    };
  };
}
