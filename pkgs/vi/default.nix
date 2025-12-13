{
  writeShellApplication,
  neovim,
}:
writeShellApplication {
  name = "vi";
  runtimeInputs = [neovim];
  text = ''
    exec nvim "$@"
  '';
}
