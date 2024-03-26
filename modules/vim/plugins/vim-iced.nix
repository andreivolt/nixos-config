with (import <nixpkgs> { });

vimUtils.buildVimPlugin {
  name = "vim-iced";
  src = fetchFromGitHub {
    owner = "liquidz";
    repo = "vim-iced";
    rev = "ea2cb830ccecd3ce9d4d21de55c58b59c5ca86a9";
    sha256 = "1m4rn68gcj5ikiz21sh50gyz9f4g634zzhn178avhwgdfbjs8ryl";
  };
}
