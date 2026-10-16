{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf mkOption;

  cfg = config.rc.ssh;
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
      # The Macs log in to the servers with the YubiKeys (keys.yubikeys);
      # `ssh-keygen -K` recreates these files from either key. IdentitiesOnly
      # keeps gpg-agent from offering its own key first. id_ed25519 stays as
      # a fallback until the old login keys leave authorized_keys.
      matchBlocks."glyph spore zeta stroma *.note-iwato.ts.net" = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin (lib.hm.dag.entryBefore ["*"] {
        identityFile = [
          "~/.ssh/id_ed25519_sk_rc_a"
          "~/.ssh/id_ed25519_sk_rc_b"
          "~/.ssh/id_ed25519"
        ];
        identitiesOnly = true;
        # gpg-agent can't hold security keys
        addKeysToAgent = "no";
      });
      extraConfig = ''
        IgnoreUnknown UseKeychain
        UseKeychain yes
      '';
    };
  };
}
