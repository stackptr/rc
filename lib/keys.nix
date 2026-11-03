let
  firstLine = str: builtins.head (builtins.split "\n" str);
  readKey = host:
    firstLine (builtins.readFile ./../hosts/${host}/key.pub);
  hostKeyPairs =
    map (h: {
      name = h;
      value = readKey h;
    }) [
      "glyph"
      "lobtop"
      "Rhizome"
      "spore"
      "Stroma"
      "zeta"
    ];
in
  # keys.<host> are sshd host keys: agenix recipients and known_hosts, never
  # login keys.
  builtins.listToAttrs hostKeyPairs
  // {
    deploy = firstLine (builtins.readFile ./deploy.pub);

    # glyph's SSH client key, for its unattended jobs on spore and zeta (root).
    # The private half is glyph's agenix secret ssh-client-key, owned by mu.
    clients.glyph = firstLine (builtins.readFile ./../hosts/glyph/client.pub);

    # SSH login keys on the YubiKeys (FIDO2 ed25519-sk, resident, application
    # ssh:rc), for authorized_keys with verify-required: every login needs the
    # FIDO2 PIN and a touch. b is the offline spare.
    yubikeys = map (k: firstLine (builtins.readFile ./admin/ssh-yubikey-${k}.pub)) ["a" "b"];

    # SSH login keys in these Macs' Secure Enclaves (Secretive, Touch ID on
    # every use; hosts/<host>/secretive.pub). Plain ecdsa keys, so sshd can't
    # check the Touch ID the way verify-required checks the YubiKey PIN: the
    # requirement lives in the key's access control on the Mac.
    secureEnclave = builtins.listToAttrs (map (h: {
      name = h;
      value = firstLine (builtins.readFile ./../hosts/${h}/secretive.pub);
    }) ["Rhizome" "Stroma"]);

    # SSH login keys in the iPhones' Secure Enclaves (Rootshell, Touch ID on
    # every use). Plain ecdsa like secureEnclave, so the Touch ID is enforced
    # on the phone, not by sshd.
    phones = {
      blip = firstLine (builtins.readFile ./admin/ssh-blip.pub);
    };

    # agenix admin recipients: age-plugin-yubikey keys (PIV slot 1, PIN once,
    # touch cached). Identity files are in lib/admin/; b is the offline spare.
    admins = [
      "age1yubikey1q0h7amkmv8va7zvzd9k64l603qvafuxklq8467jsmgrhhdsc0cjdc2x33cq" # yubikey-a
      "age1yubikey1qvwy5zdaqkptwxsjx5z25jtncl4tp00m4nz6s6swnavayshlja7mjxtcn46" # yubikey-b
    ];
  }
