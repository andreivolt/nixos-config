let
  rev = "cac5bd577da26aefdabc742340a156414ac08890";
  sha256 = "11ayyqdl2a36h5zl6mmcahla4zl7rdg5nqyxbnwvmaz90gry10s1";
in import "${
  fetchTarball {
    inherit sha256;
    url = "https://github.com/Mic92/nix-ld/archive/${rev}.tar.gz";
  }
}/modules/nix-ld.nix"
