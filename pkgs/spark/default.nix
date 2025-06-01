{
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule {
  name = "spark";
  vendorHash = null;
  src = fetchFromGitHub {
    owner = "rif";
    repo = "spark";
    rev = "62769fae1f159b9849335ebad03b457854f28c18";
    sha256 = "sha256-U3OJKtBGSWLqsA5hiBvAEU8xK2jxSbZDmRnmpndhc1A=";
  };
}
