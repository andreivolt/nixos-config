with (import <nixpkgs> { });

vimUtils.buildVimPlugin {
  name = "spell-fr";
  src = [ (builtins.fetchurl ftp://ftp.vim.org/pub/vim/runtime/spell/fr.utf-8.spl) ];
  unpackPhase = ":";
  buildPhase = "mkdir -p $out/spell && cp $src $out/spell/fr.utf-8.spl";
}
