{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "firefox-sync-client";
  version = "1.8.0";

  src = fetchFromGitHub {
    owner = "Mikescher";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-Ax+v4a8bVuym1bp9dliXX85PXJk2Qlik3ME+adGiL1s=";
  };

  vendorHash = "sha256-MYetPdnnvIBzrYrA+eM9z1P3+P5FumYKH+brvvlwkm4=";

  # requires network
  doCheck = false;

  meta = with lib; rec {
    inherit (src.meta) homepage;

    description = "Interact with Firefox Sync from the command line";
    changelog = "${homepage}/releases/tag/v${version}";
    license = licenses.asl20;
    mainProgram = "ffsclient";
  };
}
