{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "runpodctl";
  version = "1.14.3";

  src = fetchFromGitHub {
    owner = "runpod";
    repo = "runpodctl";
    rev = "v${version}";
    hash = "sha256-ot/xxCL0RnMG39KDqINdAj6BSX+OLY6CusmP9Ubn8QI=";
  };

  vendorHash = "sha256-RCGUVnJl2XbSJ/L/PGLC7g9x5Pnvdaz3NlVE2XHdQYE=";

  meta = with lib; {
    description = "RunPod CLI for pod management";
    homepage = "https://github.com/runpod/runpodctl";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [siraben];
    mainProgram = "cli";
  };
}
