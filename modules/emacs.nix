{ pkgs, ... }:

{
  services.emacs.package = pkgs.emacsPgtkGcc;

  nixpkgs.overlays = [
    (import (builtins.fetchGit {
      url = "https://github.com/nix-community/emacs-overlay.git";
      ref = "master";
      rev = "bfc8f6edcb7bcf3cf24e4a7199b3f6fed96aaecf"; # change the revision
    }))
  ];

  environment.systemPackages = with pkgs; [
    emacsPgtkGcc
  ];
}

# emacs =
#   let emacs = (super.emacsPackagesNgGen super.emacs).emacsWithPackages (epkgs: with epkgs.melpaPackages; with epkgs.orgPackages; [
#     anzu
#     cider
#     cider-eval-sexp-fu
#     clj-refactor
#     clojure-mode
#     company
#     company-statistics
#     counsel
#     edit-server
#     eval-sexp-fu
#     evil
#     evil-collection
#     evil-commentary
#     evil-expat
#     evil-goggles
#     evil-indent-plus
#     evil-leader
#     evil-magit
#     evil-matchit
#     evil-numbers
#     evil-org
#     evil-snipe
#     evil-surround
#     evil-visualstar
#     git-gutter-fringe
#     git-timemachine
#     hl-todo
#     ivy
#     link-hint
#     magit
#     markdown-mode
#     multicolumn
#     nav-flash
#     neotree
#     nix-mode
#     # notmuch
#     org-bullets
#     org-plus-contrib
#     org-web-tools
#     parinfer
#     pretty-mode
#     projectile
#     ripgrep
#     smartparens
#     smex
#     sort-words
#     srefactor
#     typo
#     use-package
#     w3m
#     writeroom-mode ]);
#   in let _ = ''
#     wrapProgram $out/bin/emacs \
#       --add-flags '--directory ${builtins.toString ./.}' \
#       --add-flags '--load ${builtins.toString ./common.el}' '';
#   in super.stdenv.lib.overrideDerivation emacs (attrs: {
#     buildInputs =
#       attrs.buildInputs or [] ++ [ super.makeWrapper ] ++
#       (with super; [
#         (hunspellWithDicts (with hunspellDicts; [ en-us fr-moderne ]))
#         w3m ]);
#     installPhase = attrs.installPhase + _; });
# }
#{ config, lib, pkgs, ... }:

#with pkgs; let
#  emacs =
#    stdenv.lib.overrideDerivation
#      pkgs.emacs
#      (attrs: {
#        nativeBuildInputs =
#          attrs.nativeBuildInputs ++
#          (with pkgs; [
#            aspell aspellDicts.en aspellDicts.fr
#            w3m ]);});

#  emacs-wrapper = stdenv.mkDerivation rec {
#    name = "emacs";

#    src = [(pkgs.writeScript name ''
#      #!/usr/bin/env bash

#      exec &>/dev/null

#      ${emacs}/bin/emacs \
#        --load ~/.emacs.d/prog.el \
#        $@ &

#      disown
#    '')];

#    unpackPhase = "true";

#    installPhase = ''
#      mkdir -p $out/bin
#      cp $src $out/bin/${name}
#    '';
#  };

#in {
#  environment.systemPackages = [ (lowPrio emacs) emacs-wrapper ];
