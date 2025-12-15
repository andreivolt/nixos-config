{
  runCommand,
  babashka,
  makeWrapper,
  lib,
  andrei,
}:
runCommand "content" {
  nativeBuildInputs = [makeWrapper];
} ''
  mkdir -p $out/bin
  cp ${./content.clj} $out/bin/content
  chmod +x $out/bin/content
  wrapProgram $out/bin/content --prefix PATH : ${lib.makeBinPath [
    babashka
    andrei.x-thread
    andrei.reddit-comments
    andrei.hn-comments
    andrei.youtube-transcript
    andrei.firecrawl
    andrei.puremd
  ]}
''
