{
  runCommand,
  bun,
  makeWrapper,
}:
runCommand "hn-comments" {
  nativeBuildInputs = [makeWrapper];
} ''
  mkdir -p $out/bin
  cp ${./hn-comments.js} $out/bin/hn-comments
  chmod +x $out/bin/hn-comments
  wrapProgram $out/bin/hn-comments --prefix PATH : ${bun}/bin
''
