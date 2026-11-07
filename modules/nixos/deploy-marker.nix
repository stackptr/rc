# Logs one journal line per activation, whichever way the switch was run
# (`just switch`, `just switch-remote`, or deploy-rs from the Deploy
# workflow), so Loki has a uniform {app="nixos-deploy"} stream that names
# the flake revision. switch-to-configuration's own "switching to system
# configuration" line only carries the store path. An nvd package diff
# against the previous system follows it, so "what changed?" has an answer
# in Loki, and a summary of it goes to #updates through ntfy on glyph. It
# also writes nixos_deploy_timestamp_seconds for node_exporter's textfile
# collector, for things that can only query Prometheus (Homepage).
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

  host = config.networking.hostName;
  ntfy =
    if host == "glyph"
    then "http://127.0.0.1:2586"
    else "http://glyph.note-iwato.ts.net:2586";

  # Posts an activation's package changes to #updates through ntfy on glyph,
  # so a deploy nobody approved (spore's) still says what it changed.
  # Arguments: nvd's diff, and the previous system's revision ("" if unknown).
  notify = pkgs.writeShellApplication {
    name = "deploy-notify";
    runtimeInputs = [pkgs.coreutils pkgs.curl pkgs.gawk pkgs.gnused pkgs.jq];
    text = ''
      diff=$1
      previous=$2
      current=${revision}
      repo=https://github.com/stackptr/rc

      # "[U.]  #03  grafana  12.1.0 -> 12.2.0" becomes "grafana 12.1.0 → 12.2.0";
      # added and removed packages get a + or -
      changes=$(awk '/^\[[UDCAR].\]/ {
        state = substr($1, 2, 1); $1 = ""; $2 = ""; sub(/^ +/, "")
        gsub(/ -> /, " → ")
        print (state == "A" ? "+" : state == "R" ? "-" : "") $0
      }' <<< "$diff")
      count=$(awk 'NF' <<< "$changes" | wc -l)
      shown=$(awk 'NF && NR <= 15 { printf "%s%s", (n++ ? " · " : ""), $0 }' <<< "$changes" \
        | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g')
      if (( count == 0 )); then
        summary="No package version changes"
      elif (( count > 15 )); then
        summary="$count package changes: $shown, and $((count - 15)) more"
      else
        summary="$count package changes: $shown"
      fi

      label=''${current:0:7}
      [[ $current == *-dirty ]] && label+=" (uncommitted changes)"
      if [[ $previous =~ ^[0-9a-f]{40}$ && $current =~ ^[0-9a-f]{40}$ && $previous != "$current" ]]; then
        url="$repo/compare/$previous...$current"
        link="<$url|''${previous:0:7}…''${current:0:7}>"
      elif [[ $current =~ ^[0-9a-f]{40} ]]; then
        url="$repo/commit/''${current:0:40}"
        link="<$url|$label>"
      else
        url=$repo
        link="an unknown revision"
      fi

      jq -n --arg title "${host} deployed $label" --arg message "$link"$'\n'"$summary" --arg click "$url" '{
        topic: "notifications",
        title: $title,
        message: $message,
        tags: ["rocket"],
        click: $click
      }' | curl -s --max-time 5 -d @- ${ntfy}/ > /dev/null
    '';
  };
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
        changes=$(${pkgs.nvd}/bin/nvd --color never --nix-bin-dir ${config.nix.package}/bin \
          diff /run/current-system "$systemConfig" 2>&1) || true
        printf '%s\n' "$changes" | ${systemd-cat} -t nixos-deploy -p info || true

        # Reactivating the same system changes nothing, so it posts nothing
        if [ "$(readlink -f /run/current-system)" != "$systemConfig" ]; then
          previous=$(/run/current-system/sw/bin/nixos-version --configuration-revision 2>/dev/null) || previous=""
          ${notify}/bin/deploy-notify "$changes" "$previous" || true
        fi
      fi
    fi
  '';
}
