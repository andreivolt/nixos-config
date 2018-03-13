{ pkgs ? (import <nixpkgs> {})
, stdenv ? pkgs.stdenv
}:


pkgs.rustPlatform.buildRustPackage rec {
  name = "wsta";

  buildInputs = [ pkgs.rustc pkgs.cargo pkgs.openssl ];

  src = pkgs.fetchFromGitHub {
    owner = "esphen";
    repo = "wsta";
    rev = "edecc66da55b203906dfe765a44de7e6d29b92f5";
    sha256 = "03jbapndj2szajbr2vbn9mjzfdm4akwhb4a0mwxilcwpkpk8bxb4";
  };

  cargoSha256 = "0ad0a1zi9finad5jzicshvj7nnspjd86njkgqqd5hkhmqf1nm0ng";
}
