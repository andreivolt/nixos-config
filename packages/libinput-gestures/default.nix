{ pkgs ? (import <nixpkgs> {})
, stdenv ? pkgs.stdenv
, xdotool ? pkgs.xdotool
, makeWrapper ? pkgs.makeWrapper
, wmctrl ? pkgs.wmctrl
, fetchFromGitHub ?  pkgs.fetchFromGitHub
, bash ? pkgs.bash
, python3 ? pkgs.python3
, libinput ? pkgs.libinput
}:

stdenv.mkDerivation rec {
  version = "2.16";
  name = "libinput-gestures-${version}";
  src = fetchFromGitHub {
    owner = "bulletmark";
    repo = "libinput-gestures";
    rev = version;
    sha256 = "0ix1ygbrwjvabxpq8g4xcfdjrcc6jq79vxpbv6msaxmjxp6dv17w";
  };

  buildInputs = with pkgs; [ makeWrapper ];

  installFlags = "DESTDIR=$(out)";
  preInstall = ''
    substituteInPlace libinput-gestures-setup \
      --replace /usr/bin /bin
    substituteInPlace libinput-gestures \
      --replace "Path(sys.argv[0]).name" "\"libinput-gestures\""
    patchShebangs ./libinput-gestures-setup
  '';
  postInstall = ''
    wrapProgram $out/bin/libinput-gestures \
      --prefix PATH : "${python3}/bin:${xdotool}/bin:${wmctrl}/bin:${libinput}/bin"
    substituteInPlace $out/usr/share/applications/libinput-gestures.desktop \
      --replace /usr/bin/ $out/bin/
    substituteInPlace $out/bin/libinput-gestures-setup \
      --replace "DIR=\"/" "DIR=\"$out/"
  '';

  meta = with stdenv.lib; {
    description = "libinput gesture recognition";
    license = licenses.gpl3;
    maintainers = with maintainers; [ yorickvp ];
  };
}
