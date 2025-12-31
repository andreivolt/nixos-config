# LSP servers and formatters for neovim
pkgs:
with pkgs; [
  # LSP servers
  bash-language-server
  biome
  clojure-lsp
  lua-language-server
  nixd
  pyright
  ruby-lsp
  rust-analyzer
  typescript-language-server

  # Formatters
  ruff
  shfmt
  stylua
]
