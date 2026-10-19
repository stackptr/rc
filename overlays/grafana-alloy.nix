# nixpkgs builds grafana-alloy against systemdLibs (systemdMinimal), which has
# no compression support. Journal files from the full systemd journald are
# zstd-compressed, so alloy's libsystemd skips them and loki.source.journal
# reads nothing, without logging an error. Link the full systemd instead.
final: prev: {
  grafana-alloy = prev.grafana-alloy.override {
    systemdLibs = prev.systemd;
  };
}
