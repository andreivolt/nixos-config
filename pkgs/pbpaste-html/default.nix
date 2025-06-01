{
  fetchgit,
  lib,
  stdenv,
  darwin,
}:
stdenv.mkDerivation {
  pname = "pbpaste-html";
  version = "unstable-2023-07-15";

  src = fetchgit {
    url = "https://gist.github.com/andreivolt/e35baca9363c096253fd6741754617f0";
    rev = "babc81a6dc5ffbc7b0f96fd196e4b2ca1ccbe7ed";
    hash = "sha256-Qrc//qkk0DjOaNW/chjZKMvSKURig6bZq+pHoIQdOVo=";
  };

  nativeBuildInputs = with darwin.apple_sdk_11_0; [
    clang
  ];
  
  buildInputs = with darwin.apple_sdk_11_0.frameworks; [
    Foundation
    AppKit
  ];

  buildPhase = ''
    clang -framework Foundation -framework AppKit -o pbpaste-html pbpaste-html.swift
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp pbpaste-html $out/bin/
  '';

  meta = with lib; {
    description = "A tool to print HTML content from the clipboard using Swift and Cocoa, from https://gist.github.com/eruffaldi/6df8e5ca2b6a50a0e4528d748992a77c";
    platforms = platforms.darwin;
  };
}
