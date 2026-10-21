{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  port = 8890;
  # spore's tailnet addresses, from `tailscale ip spore`
  spore = "100.89.150.33";
  spore6 = "fd7a:115c:a1e0::a033:9621";
  home = "/var/lib/opencode";
  stromaModel = "Qwen3.8-27B-MTPLX-Optimized-Quality";
  # A shorter prompt helps a 27B model more than it helps Claude.
  context = pkgs.writeText "AGENTS.md" (import ../../../lib/llm-profile.nix inputs.llm-profile).agent;
  settings = (pkgs.formats.json {}).generate "opencode.json" {
    "$schema" = "https://opencode.ai/config.json";
    model = "stroma/${stromaModel}";
    small_model = "stroma/${stromaModel}";
    enabled_providers = ["stroma"];
    autoupdate = false;
    share = "disabled";
    instructions = ["${context}"];
    mcp.glyph = {
      type = "remote";
      url = "http://glyph:8090/mcp";
    };
    # oMLX on Stroma (hosts/Stroma/omlx.nix)
    provider.stroma = {
      npm = "@ai-sdk/openai-compatible";
      name = "Stroma";
      options.baseURL = "http://stroma.note-iwato.ts.net:8000/v1";
      # An oMLX sub-key, from opencode-env.age
      options.apiKey = "{env:STROMA_API_KEY}";
      models.${stromaModel}.name = "Qwen 3.8 27B";
    };
  };
in {
  # STROMA_API_KEY
  age.secrets.opencode-env = {
    file = ../secrets/opencode-env.age;
    owner = "opencode";
  };

  # Agents run shell commands as this user, so it gets none of mu's access:
  # no /home (mu's SSH config and keys), no /mnt pools, no other secrets
  users.users.opencode = {
    isSystemUser = true;
    group = "opencode";
    inherit home;
  };
  users.groups.opencode = {};

  # Only spore's nginx may reach the server over the tailnet, which puts
  # Pocket ID in front of it (code.zx.dev). This can't go in nixos-fw:
  # tailscaled's ts-input chain, first in filter INPUT, accepts everything
  # from tailscale0 before nixos-fw sees it. mangle INPUT runs earlier and
  # tailscaled leaves it alone; it can't REJECT, so others time out.
  #
  # Postgres trusts every local connection (hosts/glyph/services/db.nix), so
  # anything running as this user could connect as the superuser. The socket
  # is hidden from the unit below; the opencode-out chain rejects its TCP to
  # 5432 on any address.
  networking.firewall.extraCommands = ''
    ip46tables -t mangle -N opencode-in 2>/dev/null || ip46tables -t mangle -F opencode-in
    iptables -t mangle -A opencode-in -i tailscale0 -p tcp --dport ${toString port} ! -s ${spore} -j DROP
    ip6tables -t mangle -A opencode-in -i tailscale0 -p tcp --dport ${toString port} ! -s ${spore6} -j DROP
    ip46tables -t mangle -D INPUT -j opencode-in 2>/dev/null || true
    ip46tables -t mangle -I INPUT -j opencode-in

    ip46tables -N opencode-out 2>/dev/null || ip46tables -F opencode-out
    ip46tables -A opencode-out -p tcp --dport 5432 -j REJECT
    ip46tables -D OUTPUT -m owner --uid-owner opencode -j opencode-out 2>/dev/null || true
    ip46tables -I OUTPUT -m owner --uid-owner opencode -j opencode-out
  '';
  networking.firewall.extraStopCommands = ''
    ip46tables -t mangle -D INPUT -j opencode-in 2>/dev/null || true
    ip46tables -t mangle -F opencode-in 2>/dev/null || true
    ip46tables -t mangle -X opencode-in 2>/dev/null || true
    ip46tables -D OUTPUT -m owner --uid-owner opencode -j opencode-out 2>/dev/null || true
    ip46tables -F opencode-out 2>/dev/null || true
    ip46tables -X opencode-out 2>/dev/null || true
  '';

  # The home predates this unit: an earlier DynamicUser unit left it, and
  # systemd moved it into place, owned by nobody (65534), so OpenCode couldn't
  # write its database. Everything in it belongs to the agent user, so reset
  # ownership recursively on every boot and switch; modes are left alone.
  systemd.tmpfiles.settings.opencode.${home}.Z = {
    user = "opencode";
    group = "opencode";
    mode = "-";
  };

  # code.zx.dev on spore proxies here
  systemd.services.opencode-web = {
    description = "OpenCode server";
    wantedBy = ["multi-user.target"];
    wants = ["network-online.target"];
    # After the ownership reset above, at boot and on a switch
    after = ["network-online.target" "systemd-tmpfiles-setup.service" "systemd-tmpfiles-resetup.service"];
    # Give up after 5 failed starts in 5 minutes instead of looping, so the
    # "Systemd unit failed" alert fires rather than only the restart one
    startLimitIntervalSec = 300;
    startLimitBurst = 5;
    path = with pkgs; [bash coreutils findutils gnugrep gnused git];
    environment = {
      HOME = home;
      OPENCODE_CONFIG = settings;
    };
    serviceConfig = {
      User = "opencode";
      Group = "opencode";
      ExecStart = "${lib.getExe pkgs.opencode} serve --port ${toString port} --hostname 0.0.0.0";
      EnvironmentFile = config.age.secrets.opencode-env.path;
      StateDirectory = "opencode";
      StateDirectoryMode = "0700";
      WorkingDirectory = home;
      Restart = "always";
      RestartSec = 5;

      ProtectSystem = "strict";
      ProtectHome = true;
      # EnvironmentFile is read by systemd before the namespace is set up
      InaccessiblePaths = ["/mnt" "/run/agenix" "/run/agenix.d" "/run/postgresql"];
      PrivateTmp = true;
      PrivateDevices = true;
      NoNewPrivileges = true;
      CapabilityBoundingSet = "";
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectKernelLogs = true;
      ProtectControlGroups = true;
      ProtectClock = true;
      ProtectHostname = true;
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      LockPersonality = true;
      RestrictAddressFamilies = ["AF_UNIX" "AF_INET" "AF_INET6" "AF_NETLINK"];
      # Bun's JIT needs writable executable memory, so no MemoryDenyWriteExecute
      MemoryMax = "8G";
      CPUQuota = "800%";
    };
  };
}
