{
  config,
  lib,
  pkgs,
  hostname,
  ...
}: let
  inherit (lib) mkIf mkOption;

  cfg = config.rc.ssh;

  # This Mac's Secretive key, if it has one (lib/keys.nix)
  secureEnclaveKey = (import ../../lib/keys.nix).secureEnclave.${hostname} or null;
  hasSecureEnclaveKey = secureEnclaveKey != null;
in {
  options = {
    rc.ssh = {
      enable = lib.mkEnableOption "SSH home configuration";
    };
  };

  config = mkIf cfg.enable {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks = {
        "*" = let
          defaultConfig = {
            forwardAgent = false;
            addKeysToAgent = "no";
            compression = false;
            serverAliveInterval = 0;
            serverAliveCountMax = 3;
            hashKnownHosts = false;
            userKnownHostsFile = "~/.ssh/known_hosts";
            controlMaster = "no";
            controlPath = "~/.ssh/master-%r@%n:%p";
            controlPersist = "no";
          };
        in
          defaultConfig
          // {
            addKeysToAgent = "yes";
          };
        "github.com" = {
          identityFile = "~/.ssh/id_ed25519";
        };
      };
      # Apple's ssh can't use FIDO2 security keys; nixpkgs' can.
      package = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin pkgs.openssh;
      # The Macs log in to the servers with the YubiKeys (keys.yubikeys), the
      # only keys the servers accept from people, through the key handles
      # installed below. Not gpg-agent: it can't hold security keys and would only offer
      # its own key first. Connections are shared: one PIN and touch covers
      # every ssh/scp/git to that host until 10 minutes after its last session
      # closes (`ssh -O exit <host>` ends it sooner). Meanwhile any process
      # running as the user can open sessions through it without the YubiKey.
      # A Mac with a Secretive key offers it first (Touch ID) through
      # Secretive's agent; its public key in identityFile picks it out of the
      # agent. The YubiKeys stay as the fallback.
      matchBlocks."glyph spore zeta stroma *.note-iwato.ts.net" = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin (lib.hm.dag.entryBefore ["*"] {
        identityFile =
          lib.optional hasSecureEnclaveKey "${pkgs.writeText "secretive.pub" secureEnclaveKey}"
          ++ [
            "~/.ssh/id_ed25519_sk_rc_a"
            "~/.ssh/id_ed25519_sk_rc_b"
          ];
        identitiesOnly = true;
        identityAgent =
          if hasSecureEnclaveKey
          then "~/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh"
          else "none";
        addKeysToAgent = "no";
        controlMaster = "auto";
        controlPersist = "10m";
      });
      extraConfig = ''
        IgnoreUnknown UseKeychain
        UseKeychain yes
      '';
    };

    # The YubiKeys' key handles (`ssh-keygen -K` output, lib/admin/ssh-yubikey-{a,b}).
    # Not secret: a handle only points at the resident credential, and every
    # login still needs the YubiKey, its PIN and a touch (verify-required).
    # Copied rather than linked, because ssh rejects a private key file that
    # others can read, and store files are 0444.
    home.activation.sshYubikeyHandles = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin (lib.hm.dag.entryAfter ["writeBoundary"] ''
      run install -d -m 700 "$HOME/.ssh"
      run install -m 600 ${../../lib/admin/ssh-yubikey-a} "$HOME/.ssh/id_ed25519_sk_rc_a"
      run install -m 600 ${../../lib/admin/ssh-yubikey-b} "$HOME/.ssh/id_ed25519_sk_rc_b"
    '');
  };
}
