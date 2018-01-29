{ pkgs ? (import <nixpkgs> {})
, stdenv ? pkgs.stdenv
}:

pkgs.rustPlatform.buildRustPackage rec {
  name = "record-query";
  src = pkgs.fetchFromGitHub {
    owner = "dflemstr";
    repo = "rq";
    rev = "c8bbbb2cd32567bbe2e7c5711d1178376d9ffa39";
    sha256 = "0qzxpqrkd94xda5mic4469qhnh8r95igbhmg5z2lmnsbircvd99v";
  };
  buildInputs = [
    pkgs.llvmPackages.clang-unwrapped
    pkgs.v8
  ];
  depsSha256 = "1hqy0rjy65kccn75j60krf37xs3wfb6ha1q9zq5frlnhgxrcd57x";
  configurePhase = ''
    export LIBCLANG_PATH="${pkgs.llvmPackages.clang-unwrapped}/lib"
  '';
}
