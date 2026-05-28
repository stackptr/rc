{
  config,
  pkgs,
  ...
}: {
  rc.gpg.enable = true;

  age.secrets.otel-token = {
    file = ./secrets/otel-token.age;
  };

  programs.claude-code.settings.env = {
    CLAUDE_CODE_USE_BEDROCK = "1";
    AWS_REGION = "us-west-2";
    AWS_PROFILE = "bedrock";
    ANTHROPIC_DEFAULT_SONNET_MODEL = "us.anthropic.claude-sonnet-4-6";
    ANTHROPIC_DEFAULT_HAIKU_MODEL = "us.anthropic.claude-haiku-4-5-20251001-v1:0";
    CLAUDE_CODE_ENABLE_TELEMETRY = "1";
    OTEL_RESOURCE_ATTRIBUTES = "user.email=corey.johns@lob.com,user.name=Corey_Johns";
    OTEL_EXPORTER_OTLP_ENDPOINT = "https://lob.getdx.net/api/otel";
    OTEL_EXPORTER_OTLP_PROTOCOL = "http/json";
    OTEL_LOGS_EXPORTER = "otlp";
    OTEL_METRICS_EXPORTER = "otlp";
    OTEL_METRIC_EXPORT_INTERVAL = "60000";
  };

  programs.zsh.initContent = ''
    export OTEL_EXPORTER_OTLP_HEADERS="Authorization=Bearer $(cat ${config.age.secrets.otel-token.path})"
  '';
}
