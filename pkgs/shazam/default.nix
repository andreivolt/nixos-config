{
  lib,
  runCommand,
  uv,
  makeWrapper,
}:
runCommand "shazam" {
  nativeBuildInputs = [makeWrapper];
} ''
  mkdir -p $out/bin
  cp ${./shazam.py} $out/bin/shazam
  chmod +x $out/bin/shazam
  wrapProgram $out/bin/shazam --prefix PATH : ${uv}/bin
''
