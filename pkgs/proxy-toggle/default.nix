{
  lib,
  runCommand,
  uv,
  makeWrapper,
}:
runCommand "proxy-toggle" {
  nativeBuildInputs = [makeWrapper];
} ''
  mkdir -p $out/bin
  cp ${./proxy-toggle.py} $out/bin/proxy-toggle
  chmod +x $out/bin/proxy-toggle
  wrapProgram $out/bin/proxy-toggle --prefix PATH : ${uv}/bin
''
