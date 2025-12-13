{
  runCommand,
  deno,
  makeWrapper,
}:
runCommand "w3space" {
  nativeBuildInputs = [makeWrapper];
} ''
  mkdir -p $out/bin
  cp ${./w3space.ts} $out/bin/w3space
  chmod +x $out/bin/w3space
  wrapProgram $out/bin/w3space --prefix PATH : ${deno}/bin
''
