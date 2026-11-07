# Shared by the interactive agents (./agents.nix) and the tier jobs
# (./agent-tiers.nix).
{
  # oMLX on Stroma (hosts/Stroma/omlx.nix)
  stromaModel = "Qwen3.8-27B-MTPLX-Optimized-Quality";
  stromaPort = 8000;

  # The dispatcher's state, queue and runs (./agent-jobs.nix). Each run's
  # prompt goes to the tier's unit as a credential, and its output comes
  # back through StandardOutput, both opened by systemd, so the tiers never
  # read or write this directory themselves.
  dispatchHome = "/var/lib/agent-dispatch";
  # The last line of a tier unit's output: the agent's exit status
  exitMarker = "__AGENT_JOB_EXIT__";

  # systemd sandboxing for every unit that runs agents. Each adds its own
  # User, Group, Slice and ReadWritePaths.
  serviceConfig = {
    ProtectSystem = "strict";
    ProtectHome = true;
    # EnvironmentFile is read by systemd before the namespace is set up.
    # Postgres trusts every local connection (db.nix): see the firewall rules.
    # The Nix daemon's socket too: builds run as nixbld users in the daemon's
    # cgroup, outside nono, the slice's limits and the owner rules, and
    # fixed-output derivations share the host's network, so a build could
    # reach Postgres on loopback as the superuser. Nothing in these units runs
    # Nix; home-manager-opencode.service, which does, is a unit of its own.
    InaccessiblePaths = ["/mnt" "/run/agenix" "/run/agenix.d" "/run/postgresql" "/nix/var/nix/daemon-socket"];
    # Other users' processes and their command lines; the agents still see
    # their own, which Paseo lists with ps
    ProtectProc = "invisible";
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
  };
}
