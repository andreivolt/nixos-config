{
  runCommand,
  deno,
  makeWrapper,
}:
runCommand "cssq" {
  nativeBuildInputs = [makeWrapper];
} ''
  mkdir -p $out/bin
  cp ${./cssq.ts} $out/bin/cssq
  chmod +x $out/bin/cssq
  wrapProgram $out/bin/cssq --prefix PATH : ${deno}/bin
''
