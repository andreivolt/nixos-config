{
  buildGoModule,
  fetchFromGitHub,
  lib,
}:
buildGoModule rec {
  pname = "gorun";
  version = "2018-04-08";

  src = fetchFromGitHub {
    owner = "erning";
    repo = "gorun";
    rev = "85cd5f5e084af0863ed0c3f18c00e64526d1b899";
    sha256 = "1hdqimfzpynnpqc7p8m8hkcv9dlfbd8kl22979i6626nq57dvln8";
  };

  vendorHash = null; # No vendor dependencies

  meta = with lib; {
    description = "gorun is a tool enabling one to put a \"bang line\" in the source code of a Go program to run it";
    homepage = "https://github.com/erning/gorun";
    license = licenses.gpl3;
    mainProgram = "gorun";
  };
}
