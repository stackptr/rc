let
  mu = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBNIxSilxn5nzQWwdNl6NZIFU/zNUgFah2blJ1x7E2Li";
  users = [mu];

  zeta = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPlzQTrsGAD1FTVuhCW2KojrXyX5LgEUpsAXq/q7wn72";
  petrichor = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICqvZ7US1q9NDUo15xyyzXCiAGXoes0tmETy/76+nG7A";
  rhizome = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICt1ZqGf+/PV2hiuGVxbJvytEcKT0xvd4+iJZlFKtAQr";
  systems = [zeta petrichor rhizome];
  all = users ++ systems;
in {
  "userpassword.age".publicKeys = all;
  "wireless.age".publicKeys = all;
}
