{
  python3Packages,
  writers,
}:
# Python dependencies come from nixpkgs, so there's no lockfile to maintain.
writers.writePython3Bin "goodlinks-mcp" {
  libraries = with python3Packages; [httpx mcp];
  flakeIgnore = ["E501"];
} (builtins.readFile ./goodlinks_mcp.py)
