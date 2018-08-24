self: pkgs: rec {

terminal-scratchpad = with pkgs; stdenv.mkDerivation rec {
  name = "terminal-scratchpad";

  src = [(pkgs.writeScript name ''
    #!/usr/bin/env bash

    ${pkgs.tmux}/bin/tmux attach -t scratchpad ||
      ${pkgs.tmux}/bin/tmux new -s scratchpad \; set status off \; attach
  '')];

  unpackPhase = "true";

  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/${name}
  '';
};

}
