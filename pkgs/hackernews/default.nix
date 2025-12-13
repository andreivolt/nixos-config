{
  runCommand,
  deno,
  makeWrapper,
}:
runCommand "hackernews" {
  nativeBuildInputs = [makeWrapper];
} ''
  mkdir -p $out/bin
  cp ${./hackernews.ts} $out/bin/hackernews
  chmod +x $out/bin/hackernews
  wrapProgram $out/bin/hackernews --prefix PATH : ${deno}/bin
''
