with import <nixpkgs> {};

pkgs.stdenv.mkDerivation {
  name = "qutebrowser-scripts";
  src = ./.;

  phases = [ "install" ];

  buildInputs = with pkgs; [
    remarshal
    sqlite
    jq
  ]

  install = ''
    mkdir -p $out/bin
    find . \
        -maxdepth 1 \( -type f -o -type l \) \
        -executable \
        -exec cp -pL {} $out/bin \;
  '';

  meta = with stdenv.lib; {
    description = "qutebrowser scripts";
    homepage = https://github.com/andreivolt/qutebrowser-scripts;
    license = licenses.mit;
    maintainers = with maintainers; [ andreivolt ];
  };
}
