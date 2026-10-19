{
  lib,
  osConfig,
  ...
}: let
  model = "Qwen3.8-27B-MTPLX-Optimized-Quality";
  # STROMA_API_KEY=<oMLX sub-key>; aichat reads <CLIENT>_API_KEY from it.
  # A system secret (home/secrets/aichat-env.age) on the hosts that declare
  # it; aichat is only installed there.
  envFile = osConfig.age.secrets.aichat-env.path or null;
in {
  programs.aichat = {
    enable = envFile != null;
    settings = {
      model = "stroma:${model}";
      clients = [
        {
          # oMLX on Stroma (hosts/Stroma/omlx.nix)
          type = "openai-compatible";
          name = "stroma";
          api_base = "http://stroma.note-iwato.ts.net:8000/v1";
          models = [{name = model;}];
        }
      ];
    };
  };

  programs.zsh.sessionVariables = lib.mkIf (envFile != null) {
    AICHAT_ENV_FILE = envFile;
  };
}
