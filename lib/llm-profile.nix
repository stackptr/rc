# Concatenates llm-profile modules into the bundles each surface reads.
llm-profile: let
  read = f: builtins.readFile "${llm-profile}/${f}";
  bundles = builtins.fromJSON (builtins.readFile "${llm-profile}/bundles.json");
  bundle = name: builtins.concatStringsSep "\n\n" (map read bundles.${name});
in {
  chat = bundle "chat";
  agent = bundle "agent";
  "agent-standalone" = bundle "agent-standalone";
  skills = "${llm-profile}/skills";
}
