{pkgs, ...}: {
  home.packages = [pkgs.agentsview];

  # Agentsview config for pushing sessions to glyph's PostgreSQL
  home.file.".agentsview/config.toml".text = ''
    [pg]
    url = "postgres://agentsview@glyph:5432/agentsview?sslmode=disable"
    machine_name = "rhizome"
  '';

  # Push agent sessions to glyph every 10 minutes
  launchd.agents.agentsview-pg-push = {
    enable = true;
    config = {
      Program = "${pkgs.agentsview}/bin/agentsview";
      ProgramArguments = ["${pkgs.agentsview}/bin/agentsview" "pg" "push"];
      StartInterval = 600;
      StandardOutPath = "/tmp/agentsview-pg-push.log";
      StandardErrorPath = "/tmp/agentsview-pg-push.log";
    };
  };
}
