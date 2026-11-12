# Workarounds for running this Nix setup on a Mac managed by Lob's IT: MDM
# (Kandji) and Cloudflare Gateway, which inspects TLS. Revisit each one when IT
# changes what it provisions.
{
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
}
