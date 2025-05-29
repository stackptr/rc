# TODO: Building from source breaks OAuth flow; use release artifact instead.
# See: https://github.com/gitify-app/gitify/issues/2013#issuecomment-2917834558
self: super: let
  version = "6.4.1";
  src = super.fetchFromGitHub {
    owner = "gitify-app";
    repo = "gitify";
    tag = "v${version}";
    hash = "sha256-uRf+tfTiIrKc13GPSOVoEt5dFHSmJmspNc+b4cMv6Q4=";
  };
in {
  gitify = super.gitify.overrideAttrs (finalAttrs: {
    inherit version src;
    pnpmDeps = super.pnpm_9.fetchDeps {
      inherit version src;
      inherit (finalAttrs) pname;
      hash = "sha256-4Ite75ZMMSbPnmNcpoYaggiH9r2xQYkOnl29CF/6swA=";
    };
  });
}
