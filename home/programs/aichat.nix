_: let
  model = "mtplx-qwen38-27b-optimized-quality";
in {
  programs.aichat = {
    enable = true;
    settings = {
      model = "stroma:${model}";
      clients = [
        {
          type = "openai-compatible";
          name = "stroma";
          api_base = "https://stroma.note-iwato.ts.net/v1";
          models = [{name = model;}];
        }
      ];
    };
  };
}
