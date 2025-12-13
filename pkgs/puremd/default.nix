{
  writeShellApplication,
  curl,
}:
writeShellApplication {
  name = "puremd";
  runtimeInputs = [curl];
  text = ''
    if [ -z "''${1:-}" ]; then
        echo "Usage: puremd <url>" >&2
        exit 1
    fi
    curl -s "https://pure.md/$1" | head -n -3
  '';
}
