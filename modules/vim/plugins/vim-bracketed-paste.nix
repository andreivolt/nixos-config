with (import <nixpkgs> { });

vimUtils.buildVimPlugin {
  name = "vim-bracketed-paste";
  src = fetchFromGitHub {
    owner = "ConradIrwin";
    repo = "vim-bracketed-paste";
    rev = "c4c639f3cacd1b874ed6f5f196fac772e089c932";
    sha256 = "1hhi7ab36iscv9l7i64qymckccnjs9pzv0ccnap9gj5xigwz6p9h";
  };
}
