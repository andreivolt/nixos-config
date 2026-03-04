# Disable E501 line length check in writers.writePython3
inputs: final: prev: {
  writers = prev.writers // {
    writePython3 = name: attrOrCode:
      if builtins.isString attrOrCode
      then prev.writers.writePython3 name { flakeIgnore = ["E501"]; } attrOrCode
      else code: prev.writers.writePython3 name (attrOrCode // {
        flakeIgnore = (attrOrCode.flakeIgnore or []) ++ ["E501"];
      }) code;
  };
}
