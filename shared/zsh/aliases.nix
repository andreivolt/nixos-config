# Shell aliases
{ lib, pkgs, ... }:
let
  isAsahi = pkgs.stdenv.isLinux && pkgs.stdenv.hostPlatform.isAarch64;
  browser = if isAsahi then "chromium" else "chrome";
in {
  programs.zsh.shellAliases = {
    "+x" = "chmod +x";
    cdt = "cd $(mktemp -d)";
    diff = "diff --color";
    edir = "edir -r";
    eza = "eza --icons always";
    gc = "git clone --depth 1";
    gron = "fastgron";
    http = "xh";
    j = "jobs";
    jq = "gojq";
    l = "ls -1";
    la = "ls -a";
    ll = "ls -l --classify=auto --git";
    lla = "ll -a";
    ls = "eza --group-directories-first";
    mpv = "mpv --ytdl-raw-options=cookies-from-browser=${browser}";
    path = ''printf "%s\n" $path'';
    rg = "rg --smart-case --colors match:bg:yellow --colors match:fg:black";
    rm = "rm --verbose";
    scrcpy = "scrcpy --render-driver opengl";
    vi = "nvim";
    yt-dlp = "yt-dlp --cookies-from-browser ${browser}";
  } // lib.optionalAttrs pkgs.stdenv.isLinux {
    copy = "wl-copy";
    paste = "wl-paste";
  } // lib.optionalAttrs pkgs.stdenv.isDarwin {
    copy = "pbcopy";
    paste = "pbpaste";
    tailscale = "/Applications/Tailscale.app/Contents/MacOS/Tailscale";
  };

  programs.zsh.shellGlobalAliases = {
    C = "| wc -l";
    G = "| rg";
    H = "| head";
    L = "| $PAGER";
    N = "&> /dev/null";
    NE = "2> /dev/null";
    X = "| xargs";
  };
}
