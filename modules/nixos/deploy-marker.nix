# Logs one journal line per activation, whichever way the switch was run
# (`just switch`, `just switch-remote`, or deploy-rs from the Deploy
# workflow), so Loki has a uniform {app="nixos-deploy"} stream that names
# the flake revision. switch-to-configuration's own "switching to system
# configuration" line only carries the store path. An nvd package diff
# against the previous system follows it, so "what changed?" has an answer
# in Loki. It also writes nixos_deploy_timestamp_seconds for node_exporter's
# textfile collector, for things that can only query Prometheus (Homepage).
{
  config,
  inputs,
  pkgs,
  ...
}: let
  systemd-cat = "${config.systemd.package}/bin/systemd-cat";

  revision =
    if config.system.configurationRevision == null
    then "unknown"
    else config.system.configurationRevision;

  # Under /var/lib so the last deploy time survives reboots.
  textfileDir = "/var/lib/prometheus-node-exporter-textfile";
in {
  # Also makes `nixos-version --configuration-revision` answer "what's
  # deployed?". Dirty trees report "<rev>-dirty".
  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;

  services.prometheus.exporters.node.extraFlags = [
    "--collector.textfile.directory=${textfileDir}"
  ];

  system.activationScripts.deployMarker.text = ''
    # switch-to-configuration sets NIXOS_ACTION (switch, test); it's unset
    # when stage 2 activates at boot, before journald is up.
    if [ -n "''${NIXOS_ACTION-}" ]; then
      echo "action=$NIXOS_ACTION revision=${revision} system=$systemConfig" \
        | ${systemd-cat} -t nixos-deploy -p notice || true

      # Written then renamed, so a scrape never reads a partial file.
      {
        mkdir -p ${textfileDir} \
          && echo "nixos_deploy_timestamp_seconds{revision=\"${revision}\"} $(date +%s)" \
            > ${textfileDir}/deploy.prom.tmp \
          && mv ${textfileDir}/deploy.prom.tmp ${textfileDir}/deploy.prom
      } || true

      # /run/current-system still points at the previous system here; the
      # activate script repoints it after the activation scripts run. Info
      # priority keeps these lines out of the dashboards' Deploys annotation.
      if [ -e /run/current-system ]; then
        ${pkgs.nvd}/bin/nvd --color never --nix-bin-dir ${config.nix.package}/bin \
          diff /run/current-system "$systemConfig" 2>&1 \
          | ${systemd-cat} -t nixos-deploy -p info || true
      fi
    fi
  '';
}
