# Switches never change the running kernel, so a host can stay on an old one
# for weeks. While the booted kernel differs from the active system's, this
# writes nixos_reboot_required_since_seconds for node_exporter's textfile
# collector, and grafana-alerts.nix fires when it gets old.
let
  textfileDir = "/var/lib/prometheus-node-exporter-textfile";
  file = "${textfileDir}/reboot.prom";
in {
  system.activationScripts.rebootRequired.text = ''
    # At boot, activation runs before /run/booted-system exists, and the file
    # under /var/lib would otherwise outlive the reboot that cleared it
    if [ ! -e /run/booted-system ]; then
      rm -f ${file}
    else
      booted=$(readlink -f /run/booted-system/kernel /run/booted-system/kernel-modules)
      active=$(readlink -f "$systemConfig/kernel" "$systemConfig/kernel-modules")
      if [ "$booted" = "$active" ]; then
        rm -f ${file}
      elif [ ! -e ${file} ]; then
        # Kept across later switches, so it says when the reboot became due
        mkdir -p ${textfileDir} \
          && echo "nixos_reboot_required_since_seconds $(date +%s)" > ${file}.tmp \
          && mv ${file}.tmp ${file}
      fi
    fi
  '';
}
