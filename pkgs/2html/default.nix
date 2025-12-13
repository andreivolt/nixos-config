{
  runCommand,
  uv,
  makeWrapper,
}:
runCommand "2html" {
  nativeBuildInputs = [makeWrapper];
} ''
  mkdir -p $out/bin
  cp ${./2html.py} $out/bin/2html
  cp ${./2html.py.lock} $out/bin/2html.lock
  chmod +x $out/bin/2html
  wrapProgram $out/bin/2html --prefix PATH : ${uv}/bin
''
