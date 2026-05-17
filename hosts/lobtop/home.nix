{pkgs, ...}: let
  restoreScript = pkgs.writeShellScript "restore-warp-tailscale" ''
    WARP=/usr/local/bin/warp-cli

    IP_RANGES=("100.64.0.0/10")
    DNS_DOMAINS=("ts.net" "ts.zx.dev")

    log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

    apply_ip_ranges() {
      local existing
      existing=$("$WARP" tunnel ip list 2>/dev/null)
      for range in "''${IP_RANGES[@]}"; do
        if echo "$existing" | grep -qF "$range"; then
          log "IP range already present: $range"
        else
          "$WARP" tunnel ip add-range "$range" 2>/dev/null && log "Added IP range: $range"
        fi
      done
    }

    apply_dns_fallbacks() {
      local existing
      existing=$("$WARP" dns fallback list 2>/dev/null)
      for domain in "''${DNS_DOMAINS[@]}"; do
        if echo "$existing" | grep -qF "$domain"; then
          log "DNS fallback already present: $domain"
        else
          "$WARP" dns fallback add "$domain" 2>/dev/null && log "Added DNS fallback: $domain"
        fi
      done
    }

    log "Starting WARP/Tailscale restore"
    apply_ip_ranges
    apply_dns_fallbacks
    log "Done"
  '';
in {
  rc.gpg.enable = true;

  launchd.agents."com.user.restore-warp-tailscale" = {
    enable = true;
    config = {
      ProgramArguments = ["${restoreScript}"];
      WatchPaths = ["/Applications/Cloudflare WARP.app/Contents/Resources"];
      RunAtLoad = true;
      StandardOutPath = "/tmp/restore-warp-tailscale.log";
      StandardErrorPath = "/tmp/restore-warp-tailscale.log";
    };
  };
}
