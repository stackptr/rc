{
  config,
  inputs,
  lib,
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
    ./freshrss.nix
    ./grafana.nix
    ./hister.nix
    ./jellyfin.nix
    ./loki.nix
    ./navidrome.nix
    ./nfs.nix
    ./ntfy.nix
    ./open-terminal.nix
    ./open-webui.nix
    ./prometheus.nix
    ./samba.nix
    ./webdav.nix
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
    # No Tailscale SSH: it answers port 22 on the tailnet address before
    # sshd, bypassing authorized_keys. The setting persists in tailscaled's
    # state, so it has to be turned off explicitly, not just left out of up.
    extraSetFlags = ["--ssh=false"];
  };

  age.secrets.obsidian-auth-token = {
    file = ./../secrets/obsidian-auth-token.age;
    mode = "400";
    owner = "obsidian";
    group = "obsidian";
  };

  rc.obsidian-sync = {
    enable = true;
    authTokenFile = config.age.secrets.obsidian-auth-token.path;
  };

  age.secrets.kagi-api-key = {
    file = ./../secrets/kagi-api-key.age;
    mode = "440";
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

  services.basic-memory.enable = true;
  rc.backup = {
    enable = true;
    paths =
      [
        config.services.postgresqlBackup.location
        config.services.freshrss.dataDir
        "/var/lib/basic-memory"
        # Full-text index and stored pages; the rest is in Postgres
        "/var/lib/hister"
        "/var/lib/open-webui"
        "/var/lib/roon-server/backup"
      ]
      ++ lib.optional config.rc.obsidian-sync.enable config.rc.obsidian-sync.vaultPath;
  };
  services.mcp-nixos.enable = true;
  services.grafana-mcp = {
    enable = true;
    grafanaUrl = "https://monitoring.zx.dev";
    tokenFile = config.age.secrets.grafana-mcp-token.path;
  };
  services.obsidian-vault-mcp = {
    enable = true;
    inherit (config.rc.obsidian-sync) vaultPath;
  };
  services.rc-source-mcp = {
    enable = true;
    sourcePath = "${inputs.self}";
  };
  # Re-register MCP servers when a local server's unit changes (new binary,
  # flags or environment), so MCPJungle's copy of its tool list stays
  # current. rc-source is left out: its unit changes on every commit, but its
  # tool list doesn't.
  systemd.timers.mcpjungle-register.restartTriggers =
    map (name: config.systemd.units."${name}.service".unit)
    ["basic-memory" "mcp-nixos" "grafana-mcp" "hister" "obsidian-vault-mcp"];
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
      # Kagi's hosted server; it takes the API key as a bearer token.
      url = "https://mcp.kagi.com/mcp";
      description = "Kagi web search and page extraction";
      headers.Authorization = "Bearer $KAGI_API_KEY";
      environmentFile = config.age.secrets.kagi-api-key.path;
    };
    servers.grafana = {
      url = "http://127.0.0.1:8095/mcp";
      description = "Grafana dashboards, Loki logs, and Prometheus metrics";
    };
    servers.hister = {
      url = "http://127.0.0.1:4433/mcp";
      description = "Search pages I've visited (Hister): full text, stored previews, and recently indexed or opened history";
      headers.Authorization = "Bearer $HISTER_TOKEN";
      environmentFile = config.age.secrets.hister-mcp-env.path;
    };
    servers.obsidian-vault = {
      url = "http://127.0.0.1:8097/mcp";
      description = "Read and write files in the Obsidian vault";
    };
    servers.rc-source = {
      url = "http://127.0.0.1:8098/mcp";
      description = "Read-only source of my NixOS and nix-darwin configuration (github.com/stackptr/rc), as last deployed on glyph. Use it for questions about how my machines and services are set up.";
      # It serves a store path, so writes always fail; read_file is a
      # deprecated alias of read_text_file.
      disabledTools = ["create_directory" "edit_file" "move_file" "write_file" "read_file"];
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
      url = "https://docs.mcp.cloudflare.com/mcp";
      description = "Cloudflare documentation and API reference";
    };
    # Open WebUI's local model gets every tool schema in its context on each
    # turn, so it uses this subset; the full gateway stays available to it as
    # a second, opt-in tool server.
    groups.chat = {
      description = "Tools for Open WebUI";
      includedServers = ["mcp-nixos" "deepwiki" "context7"];
      includedTools =
        map (tool: "grafana__${tool}") [
          "list_datasources"
          "query_prometheus"
          "list_prometheus_metric_names"
          "list_prometheus_label_values"
          "query_loki_logs"
          "query_loki_patterns"
          "query_loki_stats"
          "list_loki_label_values"
          "search_dashboards"
          "get_dashboard_summary"
        ]
        ++ map (tool: "basic-memory__${tool}") [
          "build_context"
          "read_note"
          "recent_activity"
          "search_notes"
          "write_note"
          "edit_note"
        ]
        ++ map (tool: "hister__${tool}") [
          "search"
          "get_preview"
        ]
        ++ map (tool: "rc-source__${tool}") [
          "directory_tree"
          "list_directory"
          "read_text_file"
          "read_multiple_files"
          "search_files"
        ];
    };
  };
}
