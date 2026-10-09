# Exporters scraped by Prometheus on glyph over the tailnet (jobs "node" and
# "mactop", instance "stroma"). Both listen on all interfaces; neither has a
# flag to bind only the tailnet address.
{
  config,
  pkgs,
  ...
}: {
  # Filesystems, load, uptime: the host-level series the shared alert rules
  # and dashboards already use.
  services.prometheus.exporters.node.enable = true;

  # Apple Silicon metrics node_exporter can't read: CPU by core type, GPU
  # usage and frequency, power per component (CPU, GPU, ANE, DRAM), DRAM
  # bandwidth, SoC/GPU temperatures, thermal state and fans. Uses IOReport
  # and SMC, so no root needed.
  launchd.daemons.mactop.serviceConfig = {
    ProgramArguments = [
      "${pkgs.mactop}/bin/mactop"
      "--headless"
      "--count"
      "0"
      # Sample every 10s; Prometheus scrapes every 60s.
      "--interval"
      "10000"
      "--prometheus"
      "9101"
    ];
    UserName = config.system.primaryUser;
    RunAtLoad = true;
    KeepAlive = true;
    # Headless mode also prints every sample as JSON on stdout.
    StandardOutPath = "/dev/null";
    StandardErrorPath = "/tmp/mactop.log";
  };
}
