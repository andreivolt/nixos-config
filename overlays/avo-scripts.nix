self: pkgs: rec {

avo-scripts = with pkgs; stdenv.mkDerivation rec {
  name = "avo-scripts";

  src = fetchFromGitHub {
    owner = "andreivolt";
    repo = "scripts";
    rev = "f27eb10f5a2f34fa6d33e34aeec463669af533e8";
    sha256 = "0i7gmarv9ikp20h0hghp4ljcjwmbz7r6112c27ha4hg6k284fnj9";
  };

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
