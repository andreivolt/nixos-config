{ lib, buildGoModule }:

buildGoModule {
  pname = "lk-publish";
  version = "0.1.0";
  src = ./.;
  vendorHash = "sha256-7hmNKhTDEQ+JHHppbDQgfASUXzfam0iTcYMRfixF9Fg=";

  meta = {
    description = "Minimal H264 publisher for LiveKit";
    mainProgram = "lk-publish";
  };
}
