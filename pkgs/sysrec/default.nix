{
  writeShellApplication,
  wireplumber,
  pipewire,
}:
writeShellApplication {
  name = "sysrec";
  runtimeInputs = [wireplumber pipewire];
  text = builtins.readFile ./sysrec.sh;
}
