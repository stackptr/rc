# Secrets Management

This guide explains how to manage secrets securely using `agenix` in the Nix configuration.

## Overview

The configuration uses [agenix](https://github.com/ryantm/agenix) for secrets management. Secrets are encrypted with age and can only be decrypted by authorized hosts and users.

## Architecture

```
lib/secrets/              # Secrets definitions per host
├── default.nix          # Aggregates all host secrets  
├── spore.nix            # Secrets for spore host
├── glyph.nix            # Secrets for glyph host
└── zeta.nix             # Secrets for zeta host

hosts/<hostname>/secrets/ # Encrypted secret files
├── secret1.age          # Encrypted secret file
└── secret2.age          # Encrypted secret file

lib/keys.nix             # Public keys for encryption
```

## Key Management

### Public Keys

Public keys are defined in `lib/keys.nix`:

```nix
{
  # Host keys (from /etc/ssh/ssh_host_ed25519_key.pub)
  spore = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5...";
  glyph = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5...";
  zeta = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5...";
  
  # Admin user keys (from ~/.ssh/id_ed25519.pub)
  Petrichor = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5...";
  Rhizome = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5...";
}
```

### Adding Host Keys

1. **Get host SSH key**:
   ```bash
   ssh root@hostname 'cat /etc/ssh/ssh_host_ed25519_key.pub'
   ```

2. **Add to `lib/keys.nix`**:
   ```nix
   {
     # ... existing keys
     newhostname = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5...";
   }
   ```

3. **Create secrets file for host**:
   ```nix
   # lib/secrets/newhostname.nix
   let
     keys = with (import ../keys.nix); [newhostname Petrichor Rhizome];
   in {
     "hosts/newhostname/secrets/example-secret.age".publicKeys = keys;
   }
   ```

### Adding Admin Keys

Add your SSH public key to `lib/keys.nix` and include it in host secret definitions for administrative access.

## Creating Secrets

### 1. Create Secret File

```bash
# Create directory
mkdir -p hosts/<hostname>/secrets

# Create and edit secret
agenix -e hosts/<hostname>/secrets/my-secret.age
```

### 2. Define Secret Access

Add to `lib/secrets/<hostname>.nix`:

```nix
let
  keys = with (import ../keys.nix); [<hostname> Petrichor Rhizome];
in {
  "hosts/<hostname>/secrets/my-secret.age".publicKeys = keys;
}
```

### 3. Use Secret in Configuration

```nix
{
  config,
  pkgs,
  ...
}: {
  # Define secret
  age.secrets.my-secret = {
    file = ./secrets/my-secret.age;
    mode = "440";
    owner = "myservice";
    group = "myservice";
  };
  
  # Use in service
  services.myservice = {
    enable = true;
    secretFile = config.age.secrets.my-secret.path;
  };
}
```

## Secret Configuration Options

### File Permissions

```nix
age.secrets.my-secret = {
  file = ./secrets/my-secret.age;
  mode = "440";    # Read-only for owner and group
  owner = "user";  # Service user
  group = "group"; # Service group
};
```

### Environment Files

For services that need environment variables:

```nix
age.secrets.app-env = {
  file = ./secrets/app-env.age;
  mode = "440";
  owner = "myapp";
  group = "myapp";
};

virtualisation.oci-containers.containers.myapp = {
  image = "myapp:latest";
  environmentFiles = [
    config.age.secrets.app-env.path
  ];
};
```

### Symlink Location

Control where secrets are mounted:

```nix
age.secrets.ssl-key = {
  file = ./secrets/ssl-key.age;
  path = "/etc/ssl/private/server.key";
  mode = "440";
  owner = "nginx";
  group = "nginx";
};
```

## Principle of Least Privilege

Each host only has access to its own secrets plus admin keys:

```nix
# lib/secrets/spore.nix - spore host secrets
let
  keys = with (import ../keys.nix); [spore Petrichor Rhizome];
in {
  "hosts/spore/secrets/cloudflare-dns.age".publicKeys = keys;
  "hosts/spore/secrets/jwt-secret.age".publicKeys = keys;
  # ... other spore secrets
}

# lib/secrets/glyph.nix - glyph host secrets  
let
  keys = with (import ../keys.nix); [glyph Petrichor Rhizome];
in {
  "hosts/glyph/secrets/samba-password.age".publicKeys = keys;
  # ... other glyph secrets
}
```

## Common Secret Patterns

### Database Passwords

```nix
age.secrets.db-password = {
  file = ./secrets/db-password.age;
  mode = "440";
  owner = "postgres";
  group = "postgres";
};

services.postgresql = {
  enable = true;
  authentication = ''
    local all postgres peer
    local all all md5
  '';
  initialScript = pkgs.writeText "init.sql" ''
    ALTER USER postgres PASSWORD '${config.age.secrets.db-password.path}';
  '';
};
```

### API Keys

```nix
age.secrets.api-key = {
  file = ./secrets/api-key.age;
  mode = "440";
  owner = "myapp";
  group = "myapp";
};

services.myapp = {
  enable = true;
  extraConfig = ''
    api_key_file = "${config.age.secrets.api-key.path}"
  '';
};
```

### SSL Certificates

```nix
age.secrets.ssl-cert = {
  file = ./secrets/ssl-cert.age;
  path = "/etc/ssl/certs/server.crt";
  mode = "444";
  owner = "root";
  group = "root";
};

age.secrets.ssl-key = {
  file = ./secrets/ssl-key.age;
  path = "/etc/ssl/private/server.key";
  mode = "400";
  owner = "nginx";
  group = "nginx";
};
```

### SMTP Credentials

```nix
age.secrets.smtp-password = {
  file = ./secrets/smtp-password.age;
  mode = "440";
  owner = "authelia-main";
  group = "authelia-main";
};

services.authelia.instances.main = {
  enable = true;
  secrets = {
    notifierSMTPPasswordFile = config.age.secrets.smtp-password.path;
  };
};
```

## Secret Rotation

### 1. Update Secret Content

```bash
# Edit existing secret
agenix -e hosts/<hostname>/secrets/my-secret.age

# Or create new version
agenix -e hosts/<hostname>/secrets/my-secret-v2.age
```

### 2. Update Configuration

```nix
age.secrets.my-secret = {
  file = ./secrets/my-secret-v2.age;  # Update file reference
  mode = "440";
  owner = "myservice";
  group = "myservice";
};
```

### 3. Deploy and Clean Up

```bash
# Deploy new configuration
nixos-rebuild switch --flake .#hostname

# Remove old secret file
rm hosts/<hostname>/secrets/my-secret.age
```

## Security Best Practices

### 1. Key Management

- Use separate keys for each host
- Include admin keys for emergency access
- Rotate keys periodically
- Store admin private keys securely

### 2. Secret Organization

- Group secrets by host
- Use descriptive secret names
- Document secret purposes
- Implement least privilege access

### 3. File Permissions

- Use restrictive permissions (440, 400)
- Assign proper ownership
- Avoid world-readable secrets
- Use dedicated service users

### 4. Backup and Recovery

- Backup encrypted secret files
- Store decryption keys securely
- Test recovery procedures
- Document secret dependencies

## Troubleshooting

### Secret Access Issues

```bash
# Check secret file permissions
ls -la /run/agenix/

# Verify service user can read secret
sudo -u myservice cat /run/agenix/my-secret

# Check agenix service status
systemctl status agenix
```

### Key Problems

```bash
# Verify public key format
ssh-keygen -l -f key.pub

# Test key access
agenix -d hosts/hostname/secrets/secret.age
```

### Configuration Validation

```bash
# Check secrets configuration
nix eval .#nixosConfigurations.hostname.config.age.secrets

# Validate file paths
nix flake check
```

## Examples

See host configurations for examples:

- **spore**: Web server with SSL, SMTP, and database secrets
- **glyph**: File server with Samba authentication
- **zeta**: Home automation with service API keys

Each demonstrates different secret management patterns and security practices.