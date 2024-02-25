{ installApplication, fetchurl }:

installApplication rec {
  name = "MacPilot";
  version = "latest";
  sourceRoot = "macpilot.app";
  src = fetchurl rec {
    name = "macpilot.dmg";
    url = "https://www.koingosw.com/products/macpilot/download/macpilot.dmg";
    sha256 = "15ee0552eab36bef59c3baed3415bb12aae557cf00a5e8c11e58717705aba036";
  };
  homepage = "https://www.koingosw.com/products/macpilot/";
}
