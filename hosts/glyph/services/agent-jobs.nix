# Unattended agent jobs: events start agents without me. Each job in
# rc.agents.jobs names a trigger, a tier (./agent-tiers.nix), a prompt and a
# JSON schema for the agent's result. The dispatcher (./agent-jobs/dispatch.py),
# trusted code running as agent-dispatch, does everything else: it polls,
# dedups, fetches what the agent reads (CI logs, diffs) and passes it in,
# runs one job at a time (oMLX serves about one heavy request at a time), and
# posts the validated result through the job's sinks. Agents post nothing
# themselves, so the tiers need no GitHub token, network or write access.
#
# Kill switch: rc.agents.autonomous.enable, or at runtime
# `systemctl stop agent-jobs.target`, which stops every trigger, the worker
# and any running job.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.rc.agents;
  common = import ./agents-common.nix;
  user = "agent-dispatch";
  home = common.dispatchHome;
  tierNames = ["observe" "review"];
  jobs = lib.filterAttrs (_: job: job.enable) cfg.jobs;

  jobsJson = (pkgs.formats.json {}).generate "agent-jobs.json" (lib.mapAttrs (_: job: {
      inherit (job) tier timeout dedupKey schema sinks;
      prompt = "${job.prompt}";
      poll =
        if job.trigger.poll == null
        then null
        else "${job.trigger.poll}";
      context =
        lib.mapAttrs (_: ctx: {
          command = "${ctx.command}";
          inherit (ctx) maxBytes;
        })
        job.context;
    })
    jobs);

  dispatch =
    pkgs.writers.writePython3Bin "agent-dispatch" {
      libraries = [pkgs.python3Packages.jsonschema];
      flakeIgnore = ["E501"];
    }
    (builtins.readFile ./agent-jobs/dispatch.py);

  # The dispatcher's own GitHub token (./agents.nix, githubTokens.dispatcher):
  # Issues and Pull requests write, Contents and Actions read, rc only. Read
  # on every call, since each mint replaces the file.
  gh = pkgs.writeShellScriptBin "gh" ''
    GH_TOKEN=$(cat /run/agents-github/dispatcher/token)
    export GH_TOKEN
    exec ${lib.getExe pkgs.gh} "$@"
  '';

  unitDefaults = {
    partOf = ["agent-jobs.target"];
    after = ["network-online.target" "agents-github-token.service"];
    wants = ["network-online.target"];
    path = [dispatch gh] ++ (with pkgs; [bash coreutils gnugrep gnused jq systemd]);
    environment = {
      AGENT_JOBS = jobsJson;
      AGENT_DISPATCH_HOME = home;
      HOME = home;
      GH_CONFIG_DIR = "${home}/gh";
      GH_PROMPT_DISABLED = "1";
      GH_NO_UPDATE_NOTIFIER = "1";
    };
    serviceConfig = {
      Type = "oneshot";
      User = user;
      Group = user;
      ProtectSystem = "strict";
      ProtectHome = true;
      ReadWritePaths = [home];
      PrivateTmp = true;
      PrivateDevices = true;
      NoNewPrivileges = true;
      CapabilityBoundingSet = "";
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      RestrictSUIDSGID = true;
      LockPersonality = true;
      RestrictAddressFamilies = ["AF_UNIX" "AF_INET" "AF_INET6"];
    };
  };
in {
  imports = [./agent-jobs/flake-update.nix];

  options.rc.agents = {
    autonomous.enable = lib.mkEnableOption "unattended agent jobs (the kill switch for all of rc.agents.jobs)";

    jobs = lib.mkOption {
      default = {};
      description = "Unattended agent jobs, run by the dispatcher one at a time.";
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Whether the job's trigger runs.";
          };
          tier = lib.mkOption {
            type = lib.types.enum tierNames;
            description = "The tier the agent runs as (./agent-tiers.nix).";
          };
          trigger = {
            onCalendar = lib.mkOption {
              type = lib.types.str;
              example = "*:0/15";
              description = "When the trigger runs (systemd OnCalendar).";
            };
            poll = lib.mkOption {
              type = lib.types.nullOr lib.types.path;
              default = null;
              description = ''
                A command, run as agent-dispatch with the dispatcher's GitHub
                token, that prints one JSON event per line. Null: each run of
                the trigger is one event, `{"time": ...}`.
              '';
            };
          };
          dedupKey = lib.mkOption {
            type = lib.types.str;
            default = ".time";
            example = ".databaseId";
            description = "jq expression over an event; an event whose key the job has seen is dropped.";
          };
          prompt = lib.mkOption {
            type = lib.types.path;
            description = ''
              Prompt template. `{{event}}`, `{{schema}}`, `{{job}}`, `{{run}}`
              and `{{context.<name>}}` are filled in; context comes wrapped
              in `<untrusted-data>` delimiters.
            '';
          };
          context = lib.mkOption {
            default = {};
            description = "What the dispatcher fetches for the agent, by name.";
            type = lib.types.attrsOf (lib.types.submodule {
              options = {
                command = lib.mkOption {
                  type = lib.types.path;
                  description = "Run as agent-dispatch with the event as JSON in $EVENT; its stdout is the value.";
                };
                maxBytes = lib.mkOption {
                  type = lib.types.ints.positive;
                  default = 60000;
                  description = "Keep the last this many bytes.";
                };
              };
            });
          };
          timeout = lib.mkOption {
            type = lib.types.ints.positive;
            default = 45 * 60;
            description = "Seconds before the agent is stopped.";
          };
          schema = lib.mkOption {
            type = lib.types.attrs;
            description = "JSON schema the agent's result must match; anything else is reported as invalid, never posted.";
          };
          sinks = lib.mkOption {
            type = lib.types.listOf (lib.types.attrsOf lib.types.str);
            default = [];
            description = ''
              Where a valid result goes, in order. Each jq expression runs
              over `{job, run, event, outcome, result}`, with the result's
              strings sanitized (no control characters or @-mentions).
              - `{type = "ntfy"; publish = <jq: {title, message, click?}>;}`:
                the agents' ntfy topic, posted to #agents
              - `{type = "pr-comment"; repo; pr = <jq: number>; body = <jq: markdown>;}`
            '';
          };
        };
      });
    };
  };

  config = lib.mkIf cfg.autonomous.enable {
    systemd.targets.agent-jobs = {
      description = "Unattended agent jobs";
      wantedBy = ["multi-user.target"];
    };

    systemd.tmpfiles.settings.agent-dispatch = lib.genAttrs [home "${home}/queue" "${home}/incoming" "${home}/runs" "${home}/gh"] (_: {
      d = {
        inherit user;
        group = user;
        mode = "0700";
      };
    });

    # The worker runs whenever the queue has something in it, and works
    # through it one job at a time
    systemd.paths.agent-dispatch = {
      wantedBy = ["agent-jobs.target"];
      partOf = ["agent-jobs.target"];
      pathConfig.DirectoryNotEmpty = "${home}/queue";
    };
    systemd.services =
      {
        agent-dispatch = lib.recursiveUpdate unitDefaults {
          description = "Run queued agent jobs";
          serviceConfig = {
            ExecStart = "${lib.getExe dispatch} work";
            # A queue of jobs can take hours; each job has its own timeout
            TimeoutStartSec = "infinity";
          };
        };
      }
      // lib.mapAttrs' (name: _:
        lib.nameValuePair "agent-dispatch-poll-${name}" (lib.recursiveUpdate unitDefaults {
          description = "Poll for agent job ${name}";
          serviceConfig = {
            ExecStart = "${lib.getExe dispatch} poll ${name}";
            TimeoutStartSec = "5min";
          };
        }))
      jobs;
    systemd.timers = lib.mapAttrs' (name: job:
      lib.nameValuePair "agent-dispatch-poll-${name}" {
        wantedBy = ["agent-jobs.target"];
        partOf = ["agent-jobs.target"];
        timerConfig = {
          OnCalendar = job.trigger.onCalendar;
          RandomizedDelaySec = "1min";
        };
      })
    jobs;

    # agent-dispatch may start the tiers' template units and nothing else.
    # polkit sees the unit's name, not its properties, so this is safe only
    # because the templates fix User, sandboxing and ExecStart; never let it
    # start transient units.
    # For `sudo -u agent-dispatch agent-dispatch forget <job> <key>`
    environment.systemPackages = [dispatch];

    security.polkit.enable = true;
    security.polkit.extraConfig = ''
      polkit.addRule(function (action, subject) {
        if (action.id == "org.freedesktop.systemd1.manage-units" &&
            subject.user == "${user}" &&
            action.lookup("verb") == "start" &&
            /^agent-job-(${lib.concatStringsSep "|" tierNames})@[a-z0-9-]+\.service$/.test(action.lookup("unit"))) {
          return polkit.Result.YES;
        }
      });
    '';
  };
}
