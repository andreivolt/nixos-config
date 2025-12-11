{
  lib,
  rustPlatform,
  pkg-config,
  openssl,
}:

rustPlatform.buildRustPackage {
  pname = "paragraphs";
  version = "0.1.0";

  src = ./.;

  cargoHash = "sha256-+n5sZjX3UgllDvbtyL7WMG3x2EBxw9OeuIamx8tZ2cs=";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl ];

  meta = with lib; {
    description = "Split text into meaningful paragraphs using LLM";
    license = licenses.mit;
    mainProgram = "paragraphs";
  };
}
