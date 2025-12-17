{
  lib,
  stdenv,
  makeWrapper,
  replaceVars,
  patchelf,
  curl,
  jq,
  libnotify,
  glibc,
}:
let
  dynamicLinker =
    if stdenv.hostPlatform.system == "x86_64-linux"
    then "${glibc}/lib/ld-linux-x86-64.so.2"
    else if stdenv.hostPlatform.system == "aarch64-linux"
    then "${glibc}/lib/ld-linux-aarch64.so.1"
    else throw "Unsupported system: ${stdenv.hostPlatform.system}";
in
stdenv.mkDerivation {
  pname = "claude-code";
  version = "1.0.0";

  src = replaceVars ./claude.sh {
    patchelf = "${patchelf}/bin/patchelf";
    dynamicLinker = dynamicLinker;
    jq = "${jq}/bin/jq";
    curl = "${curl}/bin/curl";
    notify = "${libnotify}/bin/notify-send";
  };

  dontUnpack = true;
  dontBuild = true;

  nativeBuildInputs = [makeWrapper];

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/claude
    runHook postInstall
  '';

  meta = {
    description = "Self-updating Claude Code wrapper for NixOS";
    license = lib.licenses.unfree;
    platforms = ["x86_64-linux" "aarch64-linux"];
    mainProgram = "claude";
  };
}
