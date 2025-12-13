{
  runCommand,
  bun,
  makeWrapper,
}:
runCommand "tweet-screenshot" {
  nativeBuildInputs = [makeWrapper];
} ''
  mkdir -p $out/bin
  cp ${./tweet-screenshot.js} $out/bin/tweet-screenshot
  chmod +x $out/bin/tweet-screenshot
  wrapProgram $out/bin/tweet-screenshot --prefix PATH : ${bun}/bin
''
