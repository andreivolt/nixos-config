# Environment variables and PATH configuration
{ lib, pkgs, ... }:
let
  isAsahi = pkgs.stdenv.isLinux && pkgs.stdenv.hostPlatform.isAarch64;
  browser =
    if isAsahi then "chromium"
    else if pkgs.stdenv.isDarwin then "google-chrome"
    else "google-chrome-stable";
in {
  home.sessionVariables = {
    BROWSER = browser;
    DELTA_PAGER = "less";
    DENO_NO_UPDATE_CHECK = "1";
    EDITOR = "nvim";
    TERMINAL = "kitty --single-instance";
    LESS = "--RAW-CONTROL-CHARS --ignore-case --no-init --quit-if-one-screen --use-color --color=Sky --color=Er --color=d+c --color=u+g --color=PK --mouse --incsearch --wordwrap --prompt=?f%f .?m(%i/%m) .?lt%lt-%lb?L/%L. .?e(END):?pB%pB\\%..";
    LESSUTFCHARDEF = "E000-F8FF:p,F0000-FFFFD:p";
    MANPAGER = "nvim +Man!";
    MANWIDTH = "100";
    PAGER = "nvimpager";
    PYTHONDONTWRITEBYTECODE = "1";
    PYTHONWARNINGS = "ignore";
    UV_TOOL_BIN_DIR = "~/.local/bin";
    PKG_CONFIG_PATH = "$HOME/.nix-profile/lib/pkgconfig:/run/current-system/sw/lib/pkgconfig:\${PKG_CONFIG_PATH:-}";
  } // lib.optionalAttrs pkgs.stdenv.isDarwin {
    SHELL_SESSIONS_DISABLE = "1";
    HOMEBREW_CELLAR = "/opt/homebrew/Cellar";
    HOMEBREW_PREFIX = "/opt/homebrew";
    HOMEBREW_REPOSITORY = "/opt/homebrew";
    INFOPATH = "/opt/homebrew/share/info\${INFOPATH:+:$INFOPATH}";
    MANPATH = "/opt/homebrew/share/man\${MANPATH:+:$MANPATH}:";
    LIBRARY_PATH = "/opt/homebrew/opt/libiconv/lib\${LIBRARY_PATH:+:$LIBRARY_PATH}";
  };

  home.sessionPath = [
    "$HOME/go/bin"
    "$HOME/.npm/bin"
    "$HOME/.cargo/bin"
    "$HOME/.cache/.bun/bin"
    "$HOME/.local/bin"
    "$HOME/bin"
  ] ++ lib.optionals pkgs.stdenv.isDarwin [
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
  ];
}
