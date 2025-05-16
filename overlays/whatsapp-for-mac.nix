# See: https://github.com/NixOS/nixpkgs/pull/396440
self: super: let
  version = "2.25.14.77";
in {
  whatsapp-for-mac = super.whatsapp-for-mac.overrideAttrs (finalAttrs: {
    inherit version;
    src = super.fetchzip {
      extension = "zip";
      name = "WhatsApp.app";
      url = "https://web.whatsapp.com/desktop/mac_native/release/?version=${version}&extension=zip&configuration=Release&branch=relbranch";
      hash = "sha256-JOS0FrQ4QxbyCZQ7hIMSdX/8rijLtkJT3lnyqDAuxhY=";
    };
  });
}
