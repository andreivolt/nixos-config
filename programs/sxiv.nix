{ config, lib, pkgs, ... }:

let
  sxiv-rifle = pkgs.writeScript "sxiv-rifle" ''
    #!${pkgs.stdenv.shell}

    [ "$1" = '--' ] && shift

    abspath () {
        case "$1" in
            /*) printf "%s\n" "$1";;
            *)  printf "%s\n" "$PWD/$1";;
        esac
    }

    listfiles () {
        find -L "$(dirname "$target")" -maxdepth 1 -type f -iregex \
          '.*\(jpe?g\|bmp\|png\|gif\)$' -print0 | sort -z
    }

    target="$(abspath "$1")"
    count="$(listfiles | grep -m 1 -ZznF "$target" | cut -d: -f1)"

    if [ -n "$count" ]; then
        listfiles | xargs -0 ${pkgs.sxiv}/bin/sxiv -n "$count" --
    else
        ${pkgs.sxiv}/bin/sxiv -- "$@" # fallback
    fi
  '';

in {
  environment.systemPackages = with pkgs; [ sxiv ];

  home-manager.users.avo
    .programs.zsh.shellAliases.sxiv = sxiv-rifle;
}
