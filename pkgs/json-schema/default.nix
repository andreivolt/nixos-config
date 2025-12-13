{
  writeShellApplication,
  bun,
}:
writeShellApplication {
  name = "json-schema";
  runtimeInputs = [bun];
  text = ''
    exec bunx quicktype --lang schema "$@"
  '';
}
