{
  config,
  osConfig,
  pkgs,
  ...
}: {
  rc.gpg.enable = true;

  # MCP servers on a work machine are managed by my employer, and lobtop
  # can't reach the gateway on glyph anyway.
  rc.development.ai.gateway.enable = false;

  programs.claude-code.settings.env = {
    CLAUDE_CODE_ENABLE_TELEMETRY = "1";
    OTEL_RESOURCE_ATTRIBUTES = "user.email=corey.johns@lob.com,user.name=Corey_Johns";
    OTEL_EXPORTER_OTLP_ENDPOINT = "https://lob.getdx.net/api/otel";
    OTEL_EXPORTER_OTLP_PROTOCOL = "http/json";
    OTEL_LOGS_EXPORTER = "otlp";
    OTEL_METRICS_EXPORTER = "otlp";
    OTEL_METRIC_EXPORT_INTERVAL = "60000";
  };

  programs.zsh.initContent = ''
    export OTEL_EXPORTER_OTLP_HEADERS="Authorization=Bearer $(cat ${osConfig.age.secrets.otel-token.path})"
    if [[ -f "${config.home.homeDirectory}/Development/lob/shell-integration.zsh" ]]; then
      source ${config.home.homeDirectory}/Development/lob/shell-integration.zsh
    fi
  '';
}
