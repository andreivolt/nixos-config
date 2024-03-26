with (import <nixpkgs> { });

vimUtils.buildVimPlugin {
  name = "challenger-deep-theme";
  src = fetchFromGitHub {
    owner = "challenger-deep-theme";
    repo = "vim";
    rev = "b3109644b30f6a34279be7a7c9354360be207105";
    sha256 = "1q3zjp9p5irkwmnz2c3fk8xrpivkwv1kc3y5kzf1sxdrbicbqda8";
  };
}
