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
