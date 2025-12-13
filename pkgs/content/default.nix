{
  runCommand,
  babashka,
  makeWrapper,
}:
runCommand "content" {
  nativeBuildInputs = [makeWrapper];
} ''
  mkdir -p $out/bin
  cp ${./content.clj} $out/bin/content
  chmod +x $out/bin/content
  wrapProgram $out/bin/content --prefix PATH : ${babashka}/bin
''
