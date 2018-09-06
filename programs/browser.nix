{ lib, pkgs, ... }:

let
  disposable-browser = with pkgs; stdenv.mkDerivation rec {
    name = "disposable-browser";

    src = [(pkgs.writeScript name ''
      #!/usr/bin/env bash

      exec &>/dev/null

      ${pkgs.google-chrome-dev}/bin/google-chrome-unstable \
        --user-data-dir=$(mktemp -d) \
        --no-first-run --no-default-browser-check \
        $* &

      disown
    '')];

    unpackPhase = "true";

    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/${name}
    '';
  };

  google-chrome-dev-with-remote-debugging = with pkgs; stdenv.mkDerivation rec {
    name = "google-chrome-unstable";

    src = [(pkgs.writeScript name ''
      #!/usr/bin/env bash

      exec &>/dev/null

      ${pkgs.google-chrome-dev}/bin/google-chrome-unstable \
        --remote-debugging-port=9222 &

      disown
    '')];

    unpackPhase = "true";

    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/${name}
    '';
  };

in {
  environment.variables.BROWSER = "${google-chrome-dev-with-remote-debugging}/bin/google-chrome-unstable";

  programs.zsh.interactiveShellInit = lib.mkAfter "
    alias browser='$BROWSER'";

  environment.systemPackages = with pkgs; [
    (lowPrio google-chrome-dev)
    disposable-browser
    google-chrome-dev-with-remote-debugging
  ];
}
