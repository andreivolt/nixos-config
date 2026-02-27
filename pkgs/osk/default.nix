{
  lib,
  craneLib,
  pkg-config,
  libxkbcommon,
  wayland,
  makeWrapper,
  dejavu_fonts,
}:
let
  src = lib.cleanSourceWith {
    src = ./.;
    filter = path: type:
      (craneLib.filterCargoSources path type) || (lib.hasSuffix ".ttf" path);
  };
  commonArgs = {
    inherit src;
    pname = "osk";
    version = "0.1.0";
    nativeBuildInputs = [ pkg-config makeWrapper ];
    buildInputs = [ libxkbcommon wayland ];
  };
  cargoArtifacts = craneLib.buildDepsOnly commonArgs;
in
craneLib.buildPackage (commonArgs // {
  inherit cargoArtifacts;

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
})
