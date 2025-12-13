{
  runCommand,
  bun,
  makeWrapper,
}:
runCommand "hn" {
  nativeBuildInputs = [makeWrapper];
} ''
  mkdir -p $out/bin
  cp ${./hn.js} $out/bin/hn
  chmod +x $out/bin/hn
  wrapProgram $out/bin/hn --prefix PATH : ${bun}/bin
''
