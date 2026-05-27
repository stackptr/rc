# Workaround for crates.io blocking bare curl User-Agents (HTTP 403).
# crates.io enforces a data access policy requiring descriptive User-Agents;
# nixpkgs fetchcrate sends none. Remove this overlay once upstream fixes it.
# https://crates.io/data-access
final: prev: {
  fetchcrate = args:
    prev.fetchcrate (args
      // {
        curlOptsList =
          (args.curlOptsList or [])
          ++ [
            "--user-agent"
            "cargo/1.0 (nixpkgs; https://github.com/NixOS/nixpkgs)"
          ];
      });
}
