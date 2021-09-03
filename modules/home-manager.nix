let
  rev = "604561ba9ac45ee30385670b18f15731c541287b";
  sha256 = "01mj8kqk8gv5v64dmbhx5mk0sz22cs2i0jybnlicv7318xzndzxk";
in import "${
  fetchTarball {
    inherit sha256;
    url = "https://github.com/nix-community/home-manager/archive/${rev}.tar.gz";
  }
}/nixos"
