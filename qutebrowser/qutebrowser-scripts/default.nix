self: pkgs: rec {

avo-scripts = with pkgs; stdenv.mkDerivation rec {
  name = "avo-scripts";

  src = ../scripts;

  installPhase = ''
    mkdir -p $out/bin
    find . \
        -maxdepth 1 \( -type f -o -type l \) \
        -executable \
        -exec cp -pL {} $out/bin \;
  '';

  meta = with stdenv.lib; {
    description = "Andrei's scripts";
    homepage = https://github.com/andreivolt/scripts;
    license = licenses.mit;
    maintainers = with maintainers; [ andreivolt ];
  };
};

}
