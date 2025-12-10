{
  runCommand,
  ruby,
  makeWrapper,
}:
runCommand "cleanup" {
  nativeBuildInputs = [makeWrapper];
} ''
  mkdir -p $out/bin
  cp ${./cleanup.rb} $out/bin/cleanup
  chmod +x $out/bin/cleanup
  wrapProgram $out/bin/cleanup --prefix PATH : ${ruby}/bin
''
