# A disposable VM the coding agents (agents.nix) build and test with Nix in,
# instead of glyph's own Nix daemon. glyph's daemon runs as root, gives
# fixed-output derivations the host's network (where Postgres trusts
# loopback), and runs builds outside the agents' sandbox and slice. In the VM
# a malicious build or a daemon bug reaches a machine with no secrets, no
# services and no route to glyph or the home network.
#
# Upstream is working on isolating FOD networking (NixOS/nix#15959, pasta);
# tracked in #821. That closes the network route but not the
# daemon's attack surface, so it may not make this VM unnecessary.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  name = "builder";
  # Paths from agents.nix
  user = "opencode";
  home = "/var/lib/opencode";
  workspaces = "${home}/workspaces";

  stateDir = "${config.microvm.stateDir}/${name}";
  tap = "vm-${name}";
  mac = "02:00:00:88:00:02";
  hostAddress = "10.88.0.1";
  vmAddress = "10.88.0.2";
  uplink = "enp5s0";

  # The agents' private key, readable by them (nono grants it read-only in
  # agents.nix). It only opens the VM, so it isn't an agenix secret.
  keyDir = "${home}/.config/agent-builder";
  # The public half, shared into the VM as root's authorized_keys
  authorizedDir = "/var/lib/agent-builder/keys";
  storeImage = "${stateDir}/nix-store-overlay.img";

  # `builder '<command>'` runs a command in the VM as root. Its host key
  # changes on every boot (the VM's root is a tmpfs), and the tap is a
  # point-to-point link inside glyph, so host keys aren't checked.
  builderCmd = pkgs.writeShellScriptBin "builder" ''
    exec ${lib.getExe' pkgs.openssh "ssh"} -F none -i ${keyDir}/id_ed25519 \
      -o IdentitiesOnly=yes -o StrictHostKeyChecking=no \
      -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR \
      root@${vmAddress} "$@"
  '';
in {
  imports = [inputs.microvm.nixosModules.host];

  microvm.vms.${name} = {
    config = {
      system.stateVersion = config.system.stateVersion;

      microvm = {
        hypervisor = "cloud-hypervisor";
        vcpu = 6;
        # glyph has 31 GiB and its available memory bottoms out around 9 GiB;
        # at 8 GiB a VM running flat out could leave it about 1 GiB
        mem = 6144;
        # Free page reporting: memory the guest isn't using goes back to glyph
        balloon = true;
        # Lets cloud-hypervisor report readiness to systemd
        vsock.cid = 3;
        interfaces = [
          {
            type = "tap";
            id = tap;
            inherit mac;
          }
        ];
        shares = [
          # glyph's store as the read-only lower layer, so the VM boots
          # without a store image and starts with glyph's paths
          {
            tag = "ro-store";
            source = "/nix/store";
            mountPoint = "/nix/.ro-store";
            proto = "virtiofs";
            readOnly = true;
          }
          # At the same path as on glyph, so worktrees' .git files resolve
          {
            tag = "workspaces";
            source = workspaces;
            mountPoint = workspaces;
            proto = "virtiofs";
            readOnly = true;
          }
          {
            tag = "keys";
            source = authorizedDir;
            mountPoint = "/var/lib/agent-builder-keys";
            proto = "virtiofs";
            readOnly = true;
          }
        ];
        # Builds write here; deleted before every start (below)
        writableStoreOverlay = "/nix/.rw-store";
        volumes = [
          {
            image = storeImage;
            mountPoint = "/nix/.rw-store";
            size = 64 * 1024;
          }
        ];
      };

      networking = {
        useNetworkd = true;
        useDHCP = false;
        nameservers = ["1.1.1.1" "9.9.9.9"];
      };
      systemd.network.networks."10-uplink" = {
        matchConfig.MACAddress = mac;
        address = ["${vmAddress}/30"];
        gateway = [hostAddress];
      };

      services.openssh = {
        enable = true;
        settings = {
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
          PermitRootLogin = "prohibit-password";
        };
        authorizedKeysFiles = ["/var/lib/agent-builder-keys/authorized_keys"];
      };

      # The VM is disposable, so whoever reaches it may do anything in it,
      # Nix included
      nix.settings = {
        experimental-features = ["nix-command" "flakes"];
        trusted-users = ["root"];
        # glyph's own substituter is a local address; the VM goes through
        # spore like any outside client
        extra-substituters = ["https://cache.zx.dev/main"];
        inherit (config.nix.settings) extra-trusted-public-keys;
      };
      # The root filesystem is a tmpfs in RAM; build in the overlay volume
      systemd.tmpfiles.rules = ["d /nix/.rw-store/tmp 1777 root root -"];
      systemd.services.nix-daemon.environment.TMPDIR = "/nix/.rw-store/tmp";

      # The workspaces belong to opencode on glyph, not to root
      programs.git = {
        enable = true;
        config.safe.directory = "*";
      };
    };
  };

  # The VM counts against the agents' budget (agents.nix), so it adds no
  # memory or CPU beyond what the agents could already use. A fresh store on
  # every start: nothing a build leaves behind survives a restart.
  systemd.services."microvm@${name}".serviceConfig = {
    Slice = "agents.slice";
    ExecStartPre = ["${lib.getExe' pkgs.coreutils "rm"} -f ${storeImage}"];
  };

  # microvm.nix creates the tap but leaves addressing to the host
  systemd.services."microvm-tap-interfaces@${name}".serviceConfig.ExecStartPost = [
    "${lib.getExe' pkgs.iproute2 "ip"} addr add ${hostAddress}/30 dev ${tap}"
  ];
  networking.dhcpcd.denyInterfaces = ["vm-*"];
  networking.nat = {
    enable = true;
    internalInterfaces = [tap];
    externalInterface = uplink;
  };

  # The VM may reach the internet and nothing else: not glyph (any of its
  # addresses, where every globally opened port listens), the tailnet or the
  # home network. Replies to glyph's SSH connections pass. mangle PREROUTING
  # runs before routing and before tailscaled's chains, which would accept
  # anything headed out tailscale0, and tailscaled leaves it alone.
  networking.firewall.extraCommands = ''
    ip46tables -t mangle -N ${name}-in 2>/dev/null || ip46tables -t mangle -F ${name}-in
    ip46tables -t mangle -A ${name}-in -m conntrack --ctstate ESTABLISHED,RELATED -j RETURN
    iptables -t mangle -A ${name}-in -d 0.0.0.0/8,10.0.0.0/8,100.64.0.0/10,127.0.0.0/8,169.254.0.0/16,172.16.0.0/12,192.168.0.0/16,224.0.0.0/3 -j DROP
    ip6tables -t mangle -A ${name}-in -j DROP
    ip46tables -t mangle -D PREROUTING -i ${tap} -j ${name}-in 2>/dev/null || true
    ip46tables -t mangle -I PREROUTING -i ${tap} -j ${name}-in
  '';
  networking.firewall.extraStopCommands = ''
    ip46tables -t mangle -D PREROUTING -i ${tap} -j ${name}-in 2>/dev/null || true
    ip46tables -t mangle -F ${name}-in 2>/dev/null || true
    ip46tables -t mangle -X ${name}-in 2>/dev/null || true
  '';

  systemd.tmpfiles.settings.agent-builder = {
    ${keyDir}.d = {
      inherit user;
      group = user;
      mode = "0700";
    };
    "/var/lib/agent-builder".d = {
      user = "root";
      group = "root";
      mode = "0755";
    };
    ${authorizedDir}.d = {
      user = "root";
      group = "root";
      mode = "0755";
    };
  };

  # The agents' key pair, created once. The public half is copied as root so
  # the VM's sshd accepts it for root (StrictModes).
  systemd.services.agent-builder-key = {
    description = "SSH key the coding agents use to reach the builder VM";
    after = ["systemd-tmpfiles-setup.service" "systemd-tmpfiles-resetup.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = user;
      Group = user;
      ExecStartPost = "+${lib.getExe' pkgs.coreutils "install"} -m 0644 -o root -g root ${keyDir}/id_ed25519.pub ${authorizedDir}/authorized_keys";
    };
    script = ''
      [ -e ${keyDir}/id_ed25519 ] ||
        ${lib.getExe' pkgs.openssh "ssh-keygen"} -q -t ed25519 -N "" -C agents@glyph -f ${keyDir}/id_ed25519
    '';
  };
  systemd.services."microvm-virtiofsd@${name}" = {
    requires = ["agent-builder-key.service"];
    after = ["agent-builder-key.service"];
  };

  # The `builder` command; agents.nix's builderNote tells the agents about it
  systemd.services.paseo.path = [builderCmd];
  systemd.services.opencode-web.path = [builderCmd];
}
