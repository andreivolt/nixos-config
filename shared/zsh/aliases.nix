# Shell aliases
{ lib, pkgs, ... }:
{
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
    path = ''printf "%s\n" $path'';
    rg = "rg --smart-case --colors match:bg:yellow --colors match:fg:black";
    rm = "rm --verbose";
    scrcpy = "scrcpy --render-driver opengl";
    vi = "nvim";
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
