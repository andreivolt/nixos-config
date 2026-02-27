{
  lib,
  rustPlatform,
  pkg-config,
  libxkbcommon,
  wayland,
  makeWrapper,
  dejavu_fonts,
}:
rustPlatform.buildRustPackage {
  pname = "osk";
  version = "0.1.0";

  src = ./.;

  cargoLock.lockFile = ./Cargo.lock;

  nativeBuildInputs = [ pkg-config makeWrapper ];
  buildInputs = [ libxkbcommon wayland ];

  postFixup = ''
    wrapProgram $out/bin/osk \
      --set OSK_FONT "${dejavu_fonts}/share/fonts/truetype/DejaVuSans.ttf" \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ wayland libxkbcommon ]}
  '';

  meta = {
    description = "AZERTY on-screen keyboard for Wayland with auto-show on text input focus";
    platforms = lib.platforms.linux;
    mainProgram = "osk";
  };
}
