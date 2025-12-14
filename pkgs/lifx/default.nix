{
  lib,
  rustPlatform,
  makeWrapper,
  zenity,
}:

rustPlatform.buildRustPackage {
  pname = "lifx";
  version = "0.1.0";

  src = ./.;

  cargoLock.lockFile = ./Cargo.lock;

  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    wrapProgram $out/bin/lifx \
      --prefix PATH : ${lib.makeBinPath [ zenity ]}
  '';

  meta = with lib; {
    description = "Control LIFX smart lights";
    license = licenses.mit;
    mainProgram = "lifx";
  };
}
