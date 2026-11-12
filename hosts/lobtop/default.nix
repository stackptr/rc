{username, ...}: {
  imports = [
    ./dock.nix
    ./hardware.nix
    ./programs.nix
  ];

  rc.darwin.defaults = {
    fonts = true;
    homebrew = true;
    security = true;
    system = true;
  };

  # Work's Cloudflare Gateway intercepts TLS (e.g. cache.zx.dev) with this CA.
  # MDM trusts it in the keychain, but the Nix daemon and nixpkgs' curl and git
  # read /etc/ssl/certs/ca-certificates.crt instead. Expires 2029-12-11; if IT
  # rotates it, re-export with
  # `security find-certificate -c "Gateway CA - Cloudflare Managed G2" -p /Library/Keychains/System.keychain`.
  security.pki.certificateFiles = [./cloudflare-gateway-ca.pem];

  # GUI apps get their environment from launchd, not the shell, so Node-based
  # apps (e.g. T3 driving Claude Code) otherwise reject the Gateway's certs.
  # An agent rather than launchd.user.envVariables: that option only runs
  # `launchctl setenv` at activation, so it's lost on reboot.
  launchd.user.agents.node-extra-ca-certs.serviceConfig = {
    ProgramArguments = ["/bin/launchctl" "setenv" "NODE_EXTRA_CA_CERTS" "/etc/ssl/certs/ca-certificates.crt"];
    RunAtLoad = true;
  };

  # A user secret, read by home-manager through osConfig. Decrypted at boot
  # with sshd's host key (hosts/lobtop/key.pub).
  age.secrets.otel-token = {
    file = ./secrets/otel-token.age;
    owner = username;
  };
}
