{
  writeShellApplication,
  coreutils,
}:
writeShellApplication {
  name = "stash";
  runtimeInputs = [coreutils];
  text = ''
    tmpfile=$(mktemp -t "stash.XXXXXX")
    if [ -t 0 ]; then
      cat > "$tmpfile"
    else
      cat "$tmpfile"
    fi
  '';
}
