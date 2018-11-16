self: super: {

emacs =
  let emacs = (super.emacsPackagesNgGen super.emacs).emacsWithPackages (epkgs: with epkgs.melpaPackages; with epkgs.orgPackages; [
    anzu
    cider
    cider-eval-sexp-fu
    clj-refactor
    clojure-mode
    company
    company-statistics
    counsel
    edit-server
    eval-sexp-fu
    evil
    evil-collection
    evil-commentary
    evil-expat
    evil-goggles
    evil-indent-plus
    evil-leader
    evil-magit
    evil-matchit
    evil-numbers
    evil-org
    evil-snipe
    evil-surround
    evil-visualstar
    git-gutter-fringe
    git-timemachine
    hl-todo
    ivy
    link-hint
    magit
    markdown-mode
    nav-flash
    neotree
    nix-mode
    notmuch
    org-bullets
    org-plus-contrib
    org-web-tools
    parinfer
    pretty-mode
    projectile
    ripgrep
    smartparens
    smex
    sort-words
    srefactor
    typo
    use-package
    w3m
    writeroom-mode ]);
  in let _ = ''
    wrapProgram $out/bin/emacs \
      --add-flags '--directory ${builtins.toString ./.}' \
      --add-flags '--load ${builtins.toString ./common.el}' '';
  in super.stdenv.lib.overrideDerivation emacs (attrs: {
    buildInputs =
      attrs.buildInputs or [] ++ [ super.makeWrapper ] ++
      (with super; [
        (hunspellWithDicts (with hunspellDicts; [ en-us fr-moderne ]))
        w3m ]);
    installPhase = attrs.installPhase + _; });

}
