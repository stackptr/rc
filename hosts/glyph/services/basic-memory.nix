{pkgs, ...}: {
  users.users.basic-memory = {
    isSystemUser = true;
    group = "basic-memory";
    home = "/var/lib/basic-memory";
  };
  users.groups.basic-memory = {};

  systemd.services.basic-memory = {
    description = "basic-memory MCP Server";
    after = ["network-online.target"];
    wants = ["network-online.target"];
    wantedBy = ["multi-user.target"];

    environment = {
      HOME = "/var/lib/basic-memory";
      BASIC_MEMORY_CONFIG_DIR = "/var/lib/basic-memory";
      UV_CACHE_DIR = "/var/lib/basic-memory/.cache/uv";
    };

    serviceConfig = {
      ExecStart = "${pkgs.uv}/bin/uvx basic-memory mcp --transport streamable-http --port 8091 --host 127.0.0.1";
      User = "basic-memory";
      Group = "basic-memory";
      WorkingDirectory = "/var/lib/basic-memory";
      StateDirectory = "basic-memory";
      Restart = "on-failure";
      RestartSec = 5;

      # Hardening
      NoNewPrivileges = true;
      PrivateDevices = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
      ReadWritePaths = ["/var/lib/basic-memory"];
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      RestrictSUIDSGID = true;
    };
  };
}
