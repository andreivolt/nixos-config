{
  writeShellApplication,
  bun,
}:
writeShellApplication {
  name = "json-schema";
  runtimeInputs = [bun];
  text = ''
    exec bunx --silent quicktype --lang schema "$@"
  '';
}
