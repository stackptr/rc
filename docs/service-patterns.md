# Service Configuration Patterns

This guide outlines common patterns for organizing and configuring services in the Nix configuration.

## Service Organization Patterns

### Single Service Files

For simple services, use a single `.nix` file:

```nix
# hosts/<hostname>/services/simple-service.nix
{
  config,
  pkgs,
  ...
}: {
  services.simple-service = {
    enable = true;
    port = 8080;
  };
  
  networking.firewall.allowedTCPPorts = [8080];
}
```

### Service Directories

For complex services with multiple components, use directories:

```
hosts/<hostname>/services/
├── default.nix           # Imports all services
├── web/                  # Web-related services
│   ├── default.nix       # Web services aggregator
│   ├── nginx-config.nix  # Core nginx configuration
│   ├── virtual-hosts.nix # Virtual host definitions
│   └── ssl-acme.nix      # SSL/TLS configuration
└── infrastructure/       # Infrastructure services
    ├── default.nix       # Infrastructure aggregator
    └── monitoring.nix    # Monitoring services
```

### Service Aggregators

Use `default.nix` files to aggregate related services:

```nix
# hosts/<hostname>/services/web/default.nix
{
  imports = [
    ./nginx-config.nix
    ./virtual-hosts.nix
    ./ssl-acme.nix
  ];
}
```

## Common Service Patterns

### Database Services

```nix
{
  config,
  pkgs,
  ...
}: {
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_15;
    ensureDatabases = ["myapp"];
    ensureUsers = [
      {
        name = "myapp";
        ensureDBOwnership = true;
      }
    ];
  };
  
  # Backup configuration
  services.postgresqlBackup = {
    enable = true;
    databases = ["myapp"];
    startAt = "*-*-* 02:00:00";
  };
}
```

### Web Services with Authentication

```nix
{
  config,
  pkgs,
  ...
}: {
  services.nginx.virtualHosts."app.example.com" = {
    forceSSL = true;
    useACMEHost = "example.com";
    enableAutheliaAuth = true;  # Custom option from nginx-options.nix
    locations."/".proxyPass = "http://127.0.0.1:3000";
  };
}
```

### Container Services

```nix
{
  config,
  pkgs,
  ...
}: {
  virtualisation.oci-containers.containers.myapp = {
    image = "myapp:latest";
    ports = ["3000:3000"];
    volumes = [
      "/var/lib/myapp:/data"
    ];
    environment = {
      NODE_ENV = "production";
    };
    environmentFiles = [
      config.age.secrets.myapp-env.path
    ];
  };
  
  systemd.services.podman-myapp.serviceConfig = {
    Restart = "always";
    RestartSec = "10s";
  };
}
```

### Secrets Integration

```nix
{
  config,
  pkgs,
  ...
}: {
  # Secret configuration
  age.secrets.app-secret = {
    file = ./../secrets/app-secret.age;
    mode = "440";
    owner = "myapp";
    group = "myapp";
  };
  
  # Service using secret
  services.myapp = {
    enable = true;
    secretFile = config.age.secrets.app-secret.path;
  };
  
  # Ensure service user exists
  users.users.myapp = {
    isSystemUser = true;
    group = "myapp";
  };
  users.groups.myapp = {};
}
```

## Nginx Configuration Patterns

### Custom Virtual Host Options

Define reusable virtual host options:

```nix
# services/web/nginx-options.nix
{
  config,
  pkgs,
  lib,
  ...
}: {
  options.services.nginx.virtualHosts = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule {
      options = {
        enableAutheliaAuth = lib.mkEnableOption "Enable Authelia authentication";
        useCustomProxy = lib.mkEnableOption "Use custom proxy configuration";
      };
      config = lib.mkMerge [
        (lib.mkIf config.enableAutheliaAuth {
          locations."/authelia".extraConfig = ''
            # Authelia configuration
            auth_request /authelia;
          '';
        })
        (lib.mkIf config.useCustomProxy {
          locations."/".extraConfig = ''
            # Custom proxy headers
            proxy_set_header X-Custom-Header "value";
          '';
        })
      ];
    });
  };
}
```

### SSL/ACME Configuration

Centralize SSL configuration:

```nix
# services/web/ssl-acme.nix
{
  config,
  pkgs,
  ...
}: {
  security.acme = {
    acceptTerms = true;
    defaults.email = "admin@example.com";
    certs."example.com" = {
      domain = "*.example.com";
      dnsProvider = "cloudflare";
      environmentFile = config.age.secrets.cloudflare-dns.path;
      extraDomainNames = ["example.com"];
    };
  };
  
  users.users.nginx.extraGroups = ["acme"];
}
```

## Service Dependencies

### Systemd Service Dependencies

```nix
{
  config,
  pkgs,
  ...
}: {
  systemd.services.myapp = {
    description = "My Application";
    after = ["network.target" "postgresql.service"];
    wants = ["postgresql.service"];
    wantedBy = ["multi-user.target"];
    
    serviceConfig = {
      Type = "simple";
      User = "myapp";
      Group = "myapp";
      Restart = "always";
      RestartSec = "10s";
    };
    
    script = ''
      ${pkgs.myapp}/bin/myapp
    '';
  };
}
```

### Database Initialization

```nix
{
  config,
  pkgs,
  ...
}: {
  services.postgresql = {
    enable = true;
    initialScript = pkgs.writeText "init.sql" ''
      CREATE DATABASE IF NOT EXISTS myapp;
      CREATE USER IF NOT EXISTS myapp WITH PASSWORD 'password';
      GRANT ALL PRIVILEGES ON DATABASE myapp TO myapp;
    '';
  };
}
```

## Monitoring and Logging

### Service Monitoring

```nix
{
  config,
  pkgs,
  ...
}: {
  services.prometheus.exporters.node = {
    enable = true;
    port = 9100;
    enabledCollectors = ["systemd"];
  };
  
  services.grafana = {
    enable = true;
    settings.server.http_port = 3000;
  };
}
```

### Log Management

```nix
{
  config,
  pkgs,
  ...
}: {
  services.journald.extraConfig = ''
    SystemMaxUse=1G
    MaxRetentionSec=30day
  '';
  
  # Service-specific logging
  systemd.services.myapp.serviceConfig = {
    StandardOutput = "journal";
    StandardError = "journal";
    SyslogIdentifier = "myapp";
  };
}
```

## Best Practices

### 1. Service Isolation

- Use dedicated users for each service
- Set appropriate file permissions
- Limit network access with firewall rules

### 2. Configuration Management

- Keep secrets separate from configuration
- Use environment files for sensitive data
- Validate configuration before deployment

### 3. Service Organization

- Group related services in directories
- Use descriptive file names
- Create aggregator files for complex setups

### 4. Error Handling

- Configure service restart policies
- Set up health checks
- Monitor service status

### 5. Resource Management

- Set resource limits for services
- Configure log rotation
- Monitor disk usage

## Testing Services

```bash
# Check service status
systemctl status myapp

# View service logs
journalctl -u myapp -f

# Test service configuration
nixos-rebuild dry-build --flake .#hostname

# Validate nginx configuration
nginx -t

# Test database connection
psql -U myapp -d myapp -h localhost
```

## Examples

See the following hosts for service patterns:

- **spore**: Complex web server with nginx, databases, and authentication
- **glyph**: File server with Samba and Transmission
- **zeta**: Home automation with Home Assistant and ZNC

Each demonstrates different service organization patterns and best practices.