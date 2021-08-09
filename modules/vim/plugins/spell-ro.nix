with (import <nixpkgs> {});

vimUtils.buildVimPlugin {
  name = "spell-ro";
  src = [ (builtins.fetchurl ftp://ftp.vim.org/pub/vim/runtime/spell/ro.utf-8.spl) ];
  unpackPhase = ":";
  buildPhase = "mkdir -p $out/spell && cp $src $out/spell/ro.utf-8.spl";
}
