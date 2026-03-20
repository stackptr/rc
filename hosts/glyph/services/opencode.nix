{
  config,
  pkgs,
  ...
}: let
  port = 8890;
in {
  age.secrets.opencode-env = {
    file = ./../secrets/opencode-env.age;
    mode = "440";
  };

  systemd.services.opencode = {
    description = "OpenCode AI coding agent web interface";
    after = ["network-online.target"];
    wants = ["network-online.target"];
    wantedBy = ["multi-user.target"];

    environment.HOME = "/var/lib/opencode";

    serviceConfig = {
      Type = "simple";
      DynamicUser = true;
      StateDirectory = "opencode";
      CacheDirectory = "opencode";
      WorkingDirectory = "/var/lib/opencode";
      EnvironmentFile = config.age.secrets.opencode-env.path;
      ExecStart = "${pkgs.opencode}/bin/opencode web --port ${toString port} --hostname 0.0.0.0";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
