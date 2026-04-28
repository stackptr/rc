# Custom package definitions
# These are packages not available in nixpkgs or requiring customization
self: super: {
  # Pace-aware statusline for Claude Code
  claude-pace = super.callPackage ./../packages/claude-pace/package.nix {};

  # Claude desktop app
  claude-desktop = super.callPackage ./../packages/claude-desktop/package.nix {};

  # GitHub Desktop with custom configuration
  github-desktop = super.callPackage ./../packages/github-desktop/package.nix {};

  # FastScripts automation tool for macOS
  fastscripts = super.callPackage ./../packages/fastscripts/package.nix {};

  # FileBrowser quantum fork
  filebrowser-quantum = super.callPackage ./../packages/filebrowser-quantum/package.nix {};

  # MCP Gateway
  mcpjungle = super.callPackage ./../packages/mcpjungle/package.nix {};

  # Obsidian headless sync client
  obsidian-headless = super.callPackage ./../packages/obsidian-headless/package.nix {};

  # Mochi spaced repetition software
  mochi = super.callPackage ./../packages/mochi/package.nix {};

  # Transmission client alternative
  transmissionic = super.callPackage ./../packages/transmissionic/package.nix {};

  # Ungoogled Chromium with privacy enhancements
  ungoogled-chromium = super.callPackage ./../packages/ungoogled-chromium/package.nix {};
}
