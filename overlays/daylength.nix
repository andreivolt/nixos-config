self: pkgs: rec {

#  ./client-ip-echo.nix { }

dayLength = with pkgs; haskellPackages.callPackage {
  pname = "day-length-hs";
  version = "0.1.0.0";
  src = fetchgit {
    url = "https://github.com/fizyk20/day-length-hs";
    sha256 = "0hapxsn4d6q8kqd6cd3gjdgbq7z2hn30ix624i4ad0mnifzwj92j";
    rev = "e5aac494a510c000872ceb16ea17ada41f6ef33e";
  };
  isLibrary = false;
  isExecutable = true;
  executableHaskellDepends = with haskellPackages; [ base optparse-applicative time ];
  description = "Day length calculator";
  license = stdenv.lib.licenses.mit;
};

}
