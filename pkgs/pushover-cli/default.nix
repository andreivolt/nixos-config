{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "pushover-cli";
  version = rev;
  rev = "c4cd1ba8b94d4539a9902823e55417f4efdbf511";

  vendorHash = "sha256-9GzTzqMPc0XIbUi6im+QlHAuMq4fwtqNkGyufm+OwuQ=";

  src = fetchFromGitHub {
    inherit rev;
    owner = "andreivolt";
    repo = "pushover-cli";
    sha256 = "sha256-tmL4A73+N/JkCEPT3voh59ubsBmjVmOO4rlh+ahSfyQ=";
  };
}
