{
  lib,
  rustPlatform,
}:

rustPlatform.buildRustPackage {
  pname = "semantic-filter";
  version = "0.1.0";

  src = ./.;

  cargoHash = "sha256-1dh4t7SIywVLy8QbcdE0f6O8jXeOYdASvvMk3mIhZws=";

  meta = with lib; {
    description = "Filter text semantically based on a prompt using LLM";
    license = licenses.mit;
    mainProgram = "semantic-filter";
  };
}
