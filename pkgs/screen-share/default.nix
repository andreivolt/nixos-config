{
  lib,
  runCommand,
  makeWrapper,
  babashka,
  slurp,
  wf-recorder,
  wl-clipboard,
  hyprland,
  pulseaudio,
  livekit-cli,
  lk-publish ? (callPackage ../lk-publish {}),
  callPackage,
}:
runCommand "screen-share" {
  nativeBuildInputs = [makeWrapper];
} ''
  mkdir -p $out/bin
  cp ${./screen-share.clj} $out/bin/screen-share
  chmod +x $out/bin/screen-share
  wrapProgram $out/bin/screen-share --prefix PATH : ${lib.makeBinPath [
    babashka slurp wf-recorder wl-clipboard hyprland pulseaudio livekit-cli lk-publish
  ]}
''
