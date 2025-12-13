{
  writeScriptBin,
  python3,
}:
writeScriptBin "curl2cookies" ''
  #!${python3}/bin/python3
  ${builtins.readFile ./curl2cookies.py}
''
