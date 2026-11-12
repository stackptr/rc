# Workarounds for running this Nix setup on a Mac managed by Lob's IT: MDM
# (Kandji) and Cloudflare Gateway, which inspects TLS. Revisit each one when IT
# changes what it provisions.
{pkgs, ...}: let
  # Lob's managed Claude Code config (/Library/Application Support/ClaudeCode/
  # managed-mcp.json, deployed by MDM) starts its aws-agent-toolkit MCP server
  # as `uvx mcp-proxy-for-aws-cli@latest ...` with PATH pinned to
  # /opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin, and Claude Code resolves
  # the command against that PATH, not the user's. It also points
  # SSL_CERT_FILE and REQUESTS_CA_BUNDLE at a Homebrew CA bundle that nothing
  # here provisions. This stands in for Homebrew's uvx: it runs only that
  # proxy, with Nix's uv, and falls back to the system bundle (which has the
  # Gateway CA, below) while the managed one is missing.
  lobUvx = pkgs.writeShellScriptBin "uvx" ''
    case "''${1:-}" in
      mcp-proxy-for-aws-cli@*) ;;
      *)
        echo "uvx here only runs Lob's managed AWS MCP proxy (hosts/lobtop/managed-device.nix in rc)" >&2
        exit 1
        ;;
    esac
    if [ ! -r "''${SSL_CERT_FILE:-}" ]; then
      export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
      export REQUESTS_CA_BUNDLE=$SSL_CERT_FILE
    fi
    exec ${pkgs.uv}/bin/uvx "$@"
  '';
in {
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

  # The shim must sit on the managed PATH, and /opt/homebrew/bin is the only
  # entry not owned by root or MDM. postActivation runs after the Homebrew
  # step. Never replace a real Homebrew uvx; removing this block leaves the
  # link behind, so delete /opt/homebrew/bin/uvx by hand.
  system.activationScripts.postActivation.text = ''
    uvxLink=/opt/homebrew/bin/uvx
    if [ -e "$uvxLink" ] && ! readlink "$uvxLink" | grep -q '^/nix/store/'; then
      echo "warning: $uvxLink isn't the Nix shim; leaving it alone" >&2
    else
      ln -sfn ${lobUvx}/bin/uvx "$uvxLink"
    fi
  '';
}
