{config, ...}: {
  age.secrets.n8n-encryption-key.file = ./../secrets/n8n-encryption-key.age;

  services.n8n = {
    enable = true;
    environment = {
      N8N_PORT = 5678;
      GENERIC_TIMEZONE = "America/Los_Angeles";
      N8N_VERSION_NOTIFICATIONS_ENABLED = false;
      N8N_DIAGNOSTICS_ENABLED = false;
      WEBHOOK_URL = "https://n8n.zx.dev";
      N8N_ENCRYPTION_KEY_FILE = config.age.secrets.n8n-encryption-key.path;

      # PostgreSQL via unix socket
      DB_TYPE = "postgresdb";
      DB_POSTGRESDB_HOST = "/run/postgresql";
      DB_POSTGRESDB_DATABASE = "n8n";
      DB_POSTGRESDB_USER = "n8n";
    };
  };

  systemd.services.n8n = {
    after = ["postgresql.service"];
    requires = ["postgresql.service"];
    serviceConfig.SupplementaryGroups = ["postgres"];
    restartTriggers = [config.age.secrets.n8n-encryption-key.file];
  };
}
