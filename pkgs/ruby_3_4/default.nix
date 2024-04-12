{ pkgs, ... }:

pkgs.ruby.overrideAttrs (old: {
  version = "3.4.0-preview2";
  src = pkgs.fetchFromGitHub {
    owner  = "ruby";
    repo   = "ruby";
    rev    = "v3_4_0_preview2";
    sha256 = "sha256-gaPFdWyAgR3wHYTpVyVzpsLYRW+erxBysbI1YrkFXfo=";
  };
  nativeBuildInputs = old.nativeBuildInputs ++ (with pkgs; [ ruby rustc ]);
  configureFlags = old.configureFlags ++ [
      "--with-baseruby=${pkgs.ruby}/bin/ruby"
      "--enable-yjit"
    ];
})
