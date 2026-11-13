# Coding agents on glyph: OpenCode's server (code.zx.dev) and T3 Code
# (agents.zx.dev), which runs Claude Code, OpenCode and Pi agents. Everything
# here runs as one unprivileged user, the write tier (unattended jobs that
# need less run as the other tiers' users, ./agent-tiers.nix), and every
# agent process runs inside the same nono profile, which grants the workspaces
# and the agents' own state but not T3's home (its sessions, pairing secrets
# and database) or anything else of glyph's.
# On GitHub they act as the teleomycete app: they can push branches and
# open PRs, but not change workflows, and rulesets keep them from merging.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  user = "opencode";
  home = "/var/lib/opencode";
  # Repositories the agents work on
  workspaces = "${home}/workspaces";
  # T3's base directory: its database, settings, login sessions and pairing
  # secrets. Only its worktrees and scratch folders are granted to the agents.
  t3Home = "/var/lib/t3code";
  t3Worktrees = "${t3Home}/worktrees";
  # Threads started without a project work in a folder of their own here
  t3Scratch = "${t3Home}/scratch";
  # The agents' GitHub App. A separate user mints its installation tokens
  # into tokenDir, which the agents can read but not the app's key.
  githubApp = {
    clientId = "Iv23liplzBiAJHoFzanK";
    slug = "teleomycete";
    # The bot account's user ID, not the app ID: commits made with this
    # noreply address link to the bot
    botUserId = 346624003;
    owner = "stackptr";
  };
  tokenUser = "agents-github";
  tokenDir = "/run/agents-github";
  tokenFile = "${tokenDir}/token";
  gitCredential = pkgs.writeShellScript "git-credential-agents-github" ''
    # git also calls helpers with store and erase; only get has an answer
    [ "$1" = get ] || exit 0
    echo username=x-access-token
    echo "password=$(cat ${tokenFile})"
  '';
  ghWithToken = pkgs.writeShellScriptBin "gh" ''
    GH_TOKEN=$(cat ${tokenFile})
    export GH_TOKEN
    exec ${lib.getExe pkgs.gh} "$@"
  '';
  opencodePort = 8890;
  # Paseo's old port, so agents.zx.dev's proxy on spore didn't change
  t3Port = 6767;
  # The agents reach MCPJungle only through this proxy, which serves only
  # their tool group: on MCPJungle's own port they'd get every server
  # (the Obsidian vault included) and its unauthenticated admin API
  mcpPort = 8099;
  mcpGroupPath = "/v0/groups/agents/mcp";
  mcpURL = "http://127.0.0.1:${toString mcpPort}${mcpGroupPath}";
  # Likewise ntfy: on its own port they could publish to any topic, and
  # priority 4+ on `notifications` goes to #alerts. This proxy only takes
  # publishes to the agents' topic, which the relay keeps out of #alerts
  # (./ntfy.nix).
  ntfyPort = lib.toInt (lib.removePrefix ":" config.services.ntfy-sh.settings.listen-http);
  ntfyAgentsPort = 2588;
  ntfyAgentsTopic = "agents";
  ntfyAgentsURL = "http://127.0.0.1:${toString ntfyAgentsPort}/${ntfyAgentsTopic}";
  tailnet = import ../tailnet.nix;
  # Drops tailnet connections to port unless they come from one of devices
  onlyFrom = devices: port:
    lib.concatMapStrings (device: ''
      iptables -t mangle -A opencode-in -i tailscale0 -p tcp --dport ${toString port} -s ${tailnet.${device}.v4} -j RETURN
      ip6tables -t mangle -A opencode-in -i tailscale0 -p tcp --dport ${toString port} -s ${tailnet.${device}.v6} -j RETURN
    '')
    devices
    + ''
      ip46tables -t mangle -A opencode-in -i tailscale0 -p tcp --dport ${toString port} -j DROP
    '';

  common = import ./agents-common.nix;
  inherit (common) stromaModel;
  stromaURL = "http://stroma.note-iwato.ts.net:${toString common.stromaPort}/v1";
  json = pkgs.formats.json {};

  profile = import ../../../lib/llm-profile.nix inputs.llm-profile;
  # Added to every agent's instructions. Only these agents push as the app,
  # so it isn't in llm-profile, whose prompt my own Claude Code shares.
  githubNote = ''

    ## GitHub

    You push and open pull requests as the `${githubApp.slug}[bot]` GitHub App, which only has access to the repositories it's installed on. It has no Workflows permission, so GitHub rejects any push that adds or changes a file under `.github/workflows/`, which can include merging or rebasing a branch across workflow changes on the default branch. When that happens, don't retry or work around it (don't drop, split or rewrite the commits to get them through): stop and tell the user which change needs pushing.

    You can only push branches under `agents/`: name the branch by the repo's own scheme (or the default one above) and prefix it with `agents/` (e.g. `git push origin HEAD:agents/glyph/fix-gc-options`, or `agents/fix-gc-options` in a repo without scopes); GitHub rejects pushes to any other branch. After opening a pull request, turn on auto-merge with `gh pr merge --auto --squash <number>`: it merges once CI passes and the user approves, and a push after their approval needs a new one.
  '';
  # What these agents can't see from inside the sandbox, and where to look
  # instead, so they don't ask the user to run journalctl or systemctl.
  # Claude and OpenCode reach the grafana tools through the agents' MCP
  # group; Pi has no MCP, so it doesn't get this.
  hostsNote = ''

    ## Looking at the user's hosts

    You run on glyph as `${user}`, sandboxed: you can't see other users' processes or the system journal, and you can't SSH to any host. Don't ask the user to run `journalctl`, `systemctl status` or `ps` for you: the `glyph` MCP server's grafana tools answer most of that.

    - Loki has journald from glyph, spore and zeta for 30 days: `{host="glyph", unit="t3code.service"}`, with `priority=~"[0-3]"` for errors. A unit's own stream has only its output; its start, stop and result lines come from systemd under the unit's description, not its name: `{host="glyph", app="systemd"} |= "Home Manager environment for opencode"`. Every deploy logs `{app="nixos-deploy"}`, with the revision and a package diff.
    - Prometheus has unit states (`node_systemd_unit_state`), restarts (`node_systemd_service_restart_total`) and per-unit CPU and memory (`container_cpu_usage_seconds_total`, `container_memory_working_set_bytes`, by `unit`).

    Ask the user only for what neither shows, and say what you checked first.

    ## Notifying the user

    Only when the user asks to be notified (say, when a long task finishes), publish to ntfy, which posts to their Slack: `curl -s -H 'Title: <one line>' -d '<message>' ${ntfyAgentsURL}`. Messages are plain text, so links show as text.
  '';
  # A shorter prompt helps a 27B model more than it helps Claude.
  context = pkgs.writeText "AGENTS.md" (profile.agent + githubNote + hostsNote);
  opencodeSettings = json.generate "opencode.json" {
    "$schema" = "https://opencode.ai/config.json";
    model = "stroma/${stromaModel}";
    small_model = "stroma/${stromaModel}";
    enabled_providers = ["stroma"];
    autoupdate = false;
    share = "disabled";
    instructions = ["${context}"];
    mcp.glyph = {
      type = "remote";
      url = mcpURL;
    };
    # oMLX on Stroma (hosts/Stroma/omlx.nix)
    provider.stroma = {
      npm = "@ai-sdk/openai-compatible";
      name = "Stroma";
      options.baseURL = stromaURL;
      # An oMLX sub-key, from opencode-env.age
      options.apiKey = "{env:STROMA_API_KEY}";
      models.${stromaModel}.name = "Qwen 3.8 27B";
    };
  };
  piModels = json.generate "models.json" {
    providers.stroma = {
      baseUrl = stromaURL;
      api = "openai-completions";
      apiKey = "$STROMA_API_KEY";
      models = [
        {
          id = stromaModel;
          name = "Qwen 3.8 27B";
        }
      ];
    };
  };
  piSettings = json.generate "settings.json" {
    defaultProvider = "stroma";
    defaultModel = stromaModel;
  };

  # nono adds its `default` profile: system paths read-only, ~/.ssh and other
  # credentials denied, workdir none. Paths not listed here, like the rest of
  # T3's home (its sessions, pairing secrets and database) and of /var/lib,
  # don't exist inside the sandbox.
  nonoProfile = json.generate "agents.json" {
    meta = {
      name = "agents";
      description = "Coding agents on glyph";
    };
    groups = {
      # linux_temp_read: the default profile only lets agents write /tmp, and
      # Claude Code refuses to start when it can't read its /tmp/claude-<uid>.
      # PrivateTmp makes /tmp the units' own.
      include = ["nix_runtime" "git_config" "user_caches_linux" "claude_cache_linux" "linux_temp_read"];
      # rm, mv, cp, npm, kill and so on, which agents need
      exclude = ["dangerous_commands"];
    };
    # Explicit grants only, never the working directory: a process started in
    # the home would need a grant covering ~/.ssh and the rest, which Landlock
    # can't then deny, so nono refuses to start. A process whose directory
    # isn't granted starts in /.
    filesystem = {
      read = [
        "/etc"
        # The GitHub token. The directory, not the file: each mint replaces
        # the file, and Landlock grants follow the inode the path had when
        # the sandbox started.
        tokenDir
      ];
      allow = [
        # Repositories, T3's worktrees of them, and the folders of threads
        # without a project, where agents work
        workspaces
        t3Worktrees
        t3Scratch
        "${home}/.config/opencode"
        "${home}/.local/share/opencode"
        "${home}/.local/state/opencode"
        "${home}/.claude"
        "${home}/.pi/agent"
      ];
    };
  };
  # No audit trail: nono would keep it in ~/.local/state/nono, where nothing
  # reads it, and failing to create it there stops the agent from starting.
  # The journal has each unit's output.
  nonoRun = "${lib.getExe pkgs.nono} -s run --profile agents --no-audit --";
  # T3 launches each provider through these, so every agent it starts is
  # sandboxed. Each is named like the CLI it wraps and goes first on T3's
  # PATH, so the default binary path (`claude`, `opencode`, `pi`) finds the
  # wrapper before the policy below pins it. Workers don't get Claude's token.
  sandboxed = name: command:
    pkgs.writeShellScriptBin name ''
      exec ${nonoRun} ${command} "$@"
    '';
  claudeSandboxed = sandboxed "claude" (lib.getExe pkgs.claude-code);
  opencodeSandboxed = sandboxed "opencode" "env -u CLAUDE_CODE_OAUTH_TOKEN ${lib.getExe pkgs.opencode}";
  piSandboxed = sandboxed "pi" "env -u CLAUDE_CODE_OAUTH_TOKEN ${lib.getExe pkgs.pi-coding-agent}";
  providers = [claudeSandboxed opencodeSandboxed piSandboxed];

  # The package's wrapper puts its own gh, git and codex first on PATH; its gh
  # would shadow ghWithToken, so agents would push without the app's token
  t3code = pkgs.t3code.override {
    enableCodex = false;
    enableGitHub = false;
    enableGit = false;
  };
  # Read from /etc/t3code/policy.json at every start, from T3 0.1.7; 0.1.6
  # ignores it. T3 refuses to start on a policy it can't fully enforce, so
  # the build checks it once the package can.
  t3Policy = json.generate "t3code-policy.json" {
    schemaVersion = 1;
    organization = "rc";
    supportUrl = "https://github.com/stackptr/rc/blob/main/hosts/glyph/services/agents.nix";
    settings = {
      # Granted by the nono profile; anywhere else and agents can't work there
      worktreesDirectory = {
        value = t3Worktrees;
        locked = true;
      };
      # Its Chrome needs user namespaces, which RestrictNamespaces denies
      enableAgentBrowserAccess = {
        value = false;
        locked = true;
      };
    };
    limits = {
      # Setting a ceiling hands every provider's launch settings (binary path,
      # arguments, environment) to this policy, so nobody can point one past
      # nono from the UI. nono, not T3's modes, is the boundary, so the
      # ceiling itself is the broadest mode: unattended workers need to edit
      # and run commands, which OpenCode only does without asking in
      # full-access.
      maxRuntimeMode = "full-access";
      clients = ["local-browser" "remote"];
      # A cloudflared tunnel to T3's relay, around the firewall below
      connect = false;
      telemetry = false;
      browserCookieImport = false;
      # Nix updates T3 and the providers
      updates.mode = "off";
      providers = {
        allowedDrivers = ["claudeAgent" "opencode" "pi"];
        instances = {
          claudeAgent = {
            locked = true;
            binaryPath = lib.getExe claudeSandboxed;
          };
          # Locked, so it also can't connect to a server URL instead
          opencode = {
            locked = true;
            binaryPath = lib.getExe opencodeSandboxed;
          };
          pi = {
            locked = true;
            binaryPath = lib.getExe piSandboxed;
          };
        };
      };
    };
  };
  t3PolicyChecked =
    if lib.versionAtLeast t3code.version "0.1.7"
    then
      pkgs.runCommand "t3code-policy.json" {} ''
        HOME=$TMPDIR ${lib.getExe' t3code "t3"} policy check ${t3Policy}
        cp ${t3Policy} $out
      ''
    else t3Policy;

  hardening =
    common.serviceConfig
    // {
      User = user;
      Group = user;
      Slice = "agents.slice";
      Restart = "always";
      RestartSec = 5;
      ReadWritePaths = [home];
    };
  # systemd sets SHELL from the user's passwd entry, nologin for a system
  # user, and the agents run their shell tools with it
  shell = lib.getExe pkgs.bash;
  # procps for ps: T3 reads the process table to stop agents and find the
  # ports their servers listen on
  path = [ghWithToken] ++ (with pkgs; [bash coreutils findutils gnugrep gnused git procps]);
  # Give up after 5 failed starts in 5 minutes instead of looping, so the
  # "Systemd unit failed" alert fires rather than only the restart one
  startLimit = {
    startLimitIntervalSec = 300;
    startLimitBurst = 5;
  };
in {
  # STROMA_API_KEY
  age.secrets.opencode-env = {
    file = ../secrets/opencode-env.age;
    owner = user;
  };
  # CLAUDE_CODE_OAUTH_TOKEN from `claude setup-token`, so Claude Code agents
  # use the Claude subscription. ANTHROPIC_API_KEY would take precedence and
  # bill the API instead, so don't add it.
  age.secrets.claude-code-env = {
    file = ../secrets/claude-code-env.age;
    owner = user;
  };

  # The GitHub App's private key, readable only by the minting service
  age.secrets.github-app-key = {
    file = ../../../lib/admin/github-apps/teleomycete.age;
    owner = tokenUser;
  };

  # Agents run shell commands as this user, so it gets none of mu's access:
  # no /home (mu's SSH config and keys), no /mnt pools, no other secrets
  users.users.${user} = {
    isSystemUser = true;
    group = user;
    inherit home;
  };
  users.groups.${user} = {};
  users.users.${tokenUser} = {
    isSystemUser = true;
    group = tokenUser;
  };
  users.groups.${tokenUser} = {};

  # Only spore's nginx may reach OpenCode's server or T3 over the tailnet,
  # which puts Pocket ID in front of them (code.zx.dev, agents.zx.dev). The
  # exception is T3 from the iPhone, iPad, Stroma, Rhizome and lobtop: its
  # apps can't log in to Pocket ID, so they connect directly and T3's pairing
  # is their only gate. This can't go in nixos-fw: tailscaled's ts-input
  # chain, first in filter INPUT, accepts everything from tailscale0 before
  # nixos-fw sees it. mangle INPUT runs earlier and tailscaled leaves it
  # alone; it can't REJECT, so others time out.
  #
  # Postgres trusts every local connection (hosts/glyph/services/db.nix), so
  # anything running as this user could connect as the superuser. The socket
  # is hidden from the units; the opencode-out chain rejects TCP to 5432 on
  # any address. It also rejects MCPJungle's port, so the agents use only
  # their tool group through mcpPort, the Obsidian vault's MCP server,
  # which listens on loopback where they could otherwise reach it directly,
  # and ntfy's port, so they publish only to their topic through
  # ntfyAgentsPort.
  networking.firewall.extraCommands = ''
    ip46tables -t mangle -N opencode-in 2>/dev/null || ip46tables -t mangle -F opencode-in
    ${onlyFrom ["spore"] opencodePort}${onlyFrom ["spore" "blip" "slate" "stroma" "rhizome" "lobtop"] t3Port}
    ip46tables -t mangle -D INPUT -j opencode-in 2>/dev/null || true
    ip46tables -t mangle -I INPUT -j opencode-in

    ip46tables -N opencode-out 2>/dev/null || ip46tables -F opencode-out
    ip46tables -A opencode-out -p tcp --dport 5432 -j REJECT
    ip46tables -A opencode-out -p tcp --dport ${toString config.services.mcpjungle.port} -j REJECT
    ip46tables -A opencode-out -p tcp --dport ${toString config.services.obsidian-vault-mcp.port} -j REJECT
    ip46tables -A opencode-out -p tcp --dport ${toString ntfyPort} -j REJECT
    ip46tables -D OUTPUT -m owner --uid-owner ${user} -j opencode-out 2>/dev/null || true
    ip46tables -I OUTPUT -m owner --uid-owner ${user} -j opencode-out
  '';
  networking.firewall.extraStopCommands = ''
    ip46tables -t mangle -D INPUT -j opencode-in 2>/dev/null || true
    ip46tables -t mangle -F opencode-in 2>/dev/null || true
    ip46tables -t mangle -X opencode-in 2>/dev/null || true
    ip46tables -D OUTPUT -m owner --uid-owner ${user} -j opencode-out 2>/dev/null || true
    ip46tables -F opencode-out 2>/dev/null || true
    ip46tables -X opencode-out 2>/dev/null || true
  '';

  # The agents' MCP tools: every server but the Obsidian vault. Listed rather
  # than derived, so a server added later isn't theirs until it's added here.
  services.mcpjungle.groups.agents = {
    description = "Tools for the coding agents";
    includedServers = ["aws-knowledge" "basic-memory" "cloudflare-docs" "context7" "deepwiki" "grafana" "kagi" "mcp-nixos" "rc-source"];
  };
  # Serves only that group's endpoint. proxy_pass names the path, so
  # whatever URI matched, MCPJungle sees this one.
  services.nginx = {
    enable = true;
    virtualHosts.mcp-agents = {
      listen = [
        {
          addr = "127.0.0.1";
          port = mcpPort;
        }
      ];
      locations."= ${mcpGroupPath}" = {
        proxyPass = "http://127.0.0.1:${toString config.services.mcpjungle.port}${mcpGroupPath}";
        # Streamable HTTP: responses can be long-lived event streams
        extraConfig = ''
          proxy_http_version 1.1;
          proxy_set_header Connection "";
          proxy_buffering off;
          proxy_read_timeout 1h;
        '';
      };
      locations."/".return = "404";
    };
    # Publishes to the agents' topic and nothing else: not other topics,
    # ntfy's JSON publish (which names the topic in the body) or reading
    # the topic back
    virtualHosts.ntfy-agents = {
      listen = [
        {
          addr = "127.0.0.1";
          port = ntfyAgentsPort;
        }
      ];
      locations."= /${ntfyAgentsTopic}" = {
        proxyPass = "http://127.0.0.1:${toString ntfyPort}/${ntfyAgentsTopic}";
        extraConfig = ''
          limit_except POST PUT { deny all; }
        '';
      };
      locations."/".return = "404";
    };
  };

  # One budget for every agent, so they can't starve glyph's other services
  systemd.slices.agents.sliceConfig = {
    MemoryMax = "16G";
    CPUQuota = "800%";
  };

  systemd.tmpfiles.settings.agents = let
    dir = {
      d = {
        inherit user;
        group = user;
        mode = "0700";
      };
    };
    link = target: {"L+".argument = "${target}";};
  in {
    # The home predates these units: an earlier DynamicUser unit left it,
    # and systemd moved it into place, owned by nobody (65534), so neither
    # OpenCode nor nono could write to it. Everything in it belongs to the
    # agent user, so Z resets ownership recursively; modes are left alone.
    ${home} =
      dir
      // {
        Z = {
          inherit user;
          group = user;
          mode = "-";
        };
      };
    ${workspaces} = dir;
    "${home}/.config" = dir;
    "${home}/.config/opencode" = dir;
    "${home}/.config/nono" = dir;
    "${home}/.config/nono/profiles" = dir;
    "${home}/.config/nono/profiles/agents.json" = link nonoProfile;
    # The profile grants OpenCode's data and state directories, so they have
    # to exist and be the agent user's before the first start
    "${home}/.local" = dir;
    "${home}/.local/share" = dir;
    "${home}/.local/share/opencode" = dir;
    "${home}/.local/state" = dir;
    "${home}/.local/state/opencode" = dir;
    "${home}/.claude" = dir;
    "${home}/.pi" = dir;
    "${home}/.pi/agent" = dir;
    # setgid, so the token is created in the agents' group, which can read
    # it but not replace it
    ${tokenDir}.d = {
      user = tokenUser;
      group = user;
      mode = "2750";
    };
    ${t3Home} = dir;
    # Granted by the nono profile, so it has to exist before any agent starts,
    # OpenCode's server included, even if T3 hasn't run yet
    ${t3Worktrees} = dir;
    ${t3Scratch} = dir;
  };

  # Installation tokens last an hour. Every 20 minutes, so a single failed run
  # (which fires the "Systemd unit failed" alert) doesn't let the token expire.
  systemd.services.agents-github-token = {
    description = "Mint a GitHub App installation token for the coding agents";
    wants = ["network-online.target"];
    after = ["network-online.target" "systemd-tmpfiles-setup.service" "systemd-tmpfiles-resetup.service"];
    path = with pkgs; [coreutils curl jq openssl];
    serviceConfig = {
      Type = "oneshot";
      User = tokenUser;
      Group = tokenUser;
      UMask = "0027";
      ProtectSystem = "strict";
      ProtectHome = true;
      ReadWritePaths = [tokenDir];
      PrivateTmp = true;
      PrivateDevices = true;
      NoNewPrivileges = true;
      CapabilityBoundingSet = "";
      RestrictAddressFamilies = ["AF_UNIX" "AF_INET" "AF_INET6"];
    };
    script = ''
      set -o pipefail
      b64url() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }

      # A JWT for the app, valid for 9 minutes; iat is backdated for clock skew
      now=$(date +%s)
      header=$(printf '{"alg":"RS256","typ":"JWT"}' | b64url)
      payload=$(jq -nc --argjson now "$now" --arg iss ${githubApp.clientId} \
        '{iat: ($now - 60), exp: ($now + 540), iss: $iss}' | b64url)
      signature=$(printf '%s.%s' "$header" "$payload" \
        | openssl dgst -sha256 -sign ${config.age.secrets.github-app-key.path} | b64url)
      jwt="$header.$payload.$signature"

      api() {
        curl -sSf -H "Authorization: Bearer $jwt" \
          -H "Accept: application/vnd.github+json" \
          -H "X-GitHub-Api-Version: 2022-11-28" "$@"
      }
      # The app is private, so its only installation is on ${githubApp.owner}
      installation=$(api https://api.github.com/users/${githubApp.owner}/installation | jq -er .id)
      token=$(api -X POST "https://api.github.com/app/installations/$installation/access_tokens" \
        | jq -er .token)

      printf '%s' "$token" >${tokenFile}.new
      mv ${tokenFile}.new ${tokenFile}
    '';
  };
  systemd.timers.agents-github-token = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "1m";
      OnUnitActiveSec = "20m";
    };
  };

  # code.zx.dev on spore proxies here
  systemd.services.opencode-web = {
    description = "OpenCode server";
    wantedBy = ["multi-user.target"];
    wants = ["network-online.target" "agents-github-token.service"];
    after = ["network-online.target" "systemd-tmpfiles-setup.service" "systemd-tmpfiles-resetup.service" "agents-github-token.service"];
    inherit (startLimit) startLimitIntervalSec startLimitBurst;
    inherit path;
    environment = {
      HOME = home;
      SHELL = shell;
      OPENCODE_CONFIG = opencodeSettings;
    };
    serviceConfig =
      hardening
      // {
        ExecStart = "${nonoRun} ${lib.getExe pkgs.opencode} serve --port ${toString opencodePort} --hostname 0.0.0.0";
        EnvironmentFile = config.age.secrets.opencode-env.path;
        StateDirectory = "opencode";
        StateDirectoryMode = "0700";
        WorkingDirectory = workspaces;
      };
  };

  # T3 runs Claude Code with this user's config (CLAUDE_CONFIG_DIR is
  # ~/.claude), so it uses the same module as my own Claude Code
  # (modules/home/development.nix): the llm-profile prompt, the glyph MCP
  # gateway, llm-profile's skills, the read-only permission allowlist and
  # telemetry. They follow llm-profile updates with the flake.
  home-manager.users.${user} = {
    imports = [../../../modules/home/development.nix];
    home.stateVersion = "23.11";
    rc.development.ai.enable = true;
    # Their tool group, not the whole gateway (see mcpPort). Same server name,
    # so the permission allowlist's mcp__glyph__ rules still match.
    programs.mcp.servers.glyph.url = lib.mkForce mcpURL;
    programs.claude-code = {
      # T3 runs pkgs.claude-code itself, through the nono wrapper
      package = null;
      # Appended to the llm-profile prompt development.nix sets (lines merge)
      context = lib.mkAfter (githubNote + hostsNote);
    };
    # Commits as the app's bot, and pushes with its installation token. No
    # SSH key, so SSH remotes are rewritten to HTTPS.
    programs.git = {
      enable = true;
      signing.format = null;
      settings = {
        user = {
          name = "${githubApp.slug}[bot]";
          email = "${toString githubApp.botUserId}+${githubApp.slug}[bot]@users.noreply.github.com";
        };
        credential."https://github.com".helper = "${gitCredential}";
        url."https://github.com/".insteadOf = ["git@github.com:" "ssh://git@github.com/"];
      };
    };
    # Pi's endpoint, default model and instructions. It has no MCP gateway,
    # so it gets the standalone prompt. force: tmpfiles linked the first
    # two before home-manager managed them.
    home.file = {
      ".pi/agent/models.json" = {
        source = piModels;
        force = true;
      };
      ".pi/agent/settings.json" = {
        source = piSettings;
        force = true;
      };
      ".pi/agent/AGENTS.md".text = profile."agent-standalone" + githubNote;
    };
  };

  # The admin CLI, for pairing devices (see CLAUDE.md, Coding agents)
  environment.systemPackages = [t3code];
  environment.etc."t3code/policy.json".source = t3PolicyChecked;

  # agents.zx.dev on spore proxies here. Every client, browser or app, pairs
  # with a one-time token before it can do anything, loopback included, so
  # agents can't drive T3 without one.
  systemd.services.t3code = {
    description = "T3 Code server";
    wantedBy = ["multi-user.target"];
    # Claude's config above, written by home-manager's activation unit
    wants = ["network-online.target" "home-manager-${user}.service" "agents-github-token.service"];
    after = ["network-online.target" "systemd-tmpfiles-setup.service" "systemd-tmpfiles-resetup.service" "home-manager-${user}.service" "agents-github-token.service"];
    # It reads the policy only at start
    restartTriggers = [t3PolicyChecked];
    inherit (startLimit) startLimitIntervalSec startLimitBurst;
    # The sandboxed providers first, so `claude`, `opencode` and `pi` are them
    path = providers ++ path ++ [t3code];
    environment = {
      HOME = home;
      SHELL = shell;
      # Read by the OpenCode servers T3 starts
      OPENCODE_CONFIG = opencodeSettings;
      # Keeps .claude.json inside ~/.claude, which the sandbox grants
      CLAUDE_CONFIG_DIR = "${home}/.claude";
      DISABLE_AUTOUPDATER = "1";
      # The policy turns it off from 0.1.7; this covers 0.1.6
      T3CODE_TELEMETRY_ENABLED = "false";
    };
    serviceConfig =
      hardening
      // {
        ExecStart = "${lib.getExe' t3code "t3"} serve --base-dir ${t3Home} --host 0.0.0.0 --port ${toString t3Port}";
        EnvironmentFile = [
          config.age.secrets.opencode-env.path
          config.age.secrets.claude-code-env.path
        ];
        StateDirectory = ["opencode" "t3code"];
        StateDirectoryMode = "0700";
        ReadWritePaths = [home t3Home];
        WorkingDirectory = workspaces;
        # `t3 serve` prints a one-time admin pairing token at every start: as
        # a line of its own, in the pairing URL and app link, and as a QR code.
        # In the journal it would reach Loki, which agents (and Hermes) can
        # query through grafana-mcp, so drop those lines. Pair devices with
        # `t3 auth pairing create` instead.
        LogFilterPatterns = ["~^Token: " "~#token=" "~t3code://" "~[█▀▄]"];
        # Agents get SIGTERM with the server, and up to 10s to exit
        TimeoutStopSec = 20;
      };
  };
}
