self: pkgs: rec {

qutebrowser-scripts = with pkgs; stdenv.mkDerivation rec {
  name = "qutebrowser-scripts";

  src = ../qutebrowser/qutebrowser-scripts;

  installPhase = ''
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
};

}
