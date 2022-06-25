let
  rev = "93a69d07389311ffd6ce1f4d01836bbc2faec644";
  sha256 = "0z1jzn1923g2q376z4268b4cdif96i7l6lm7bd06z19qqgciqkyz";
in import "${
  fetchTarball {
    inherit sha256;
    url = "https://github.com/nix-community/home-manager/archive/${rev}.tar.gz";
  }
}/nixos"
