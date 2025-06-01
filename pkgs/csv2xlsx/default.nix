{
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "csv2xlsx";
  version = "1.0";

  vendorHash = null;

  src = fetchFromGitHub {
    owner = "mentax";
    repo = "csv2xlsx";
    rev = "0ca60cd54d8a265ddef20ef349c7ac8ca2e3ae62";
    hash = "sha256-GkLIRtMB8PYTjRw61AQvEW4gGIrtlu3Az3gRGR9wcfc=";
  };
}
