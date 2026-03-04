# Build kitty from master for momentum scrolling + pixel scrolling
inputs: final: prev: let
  kittySrc = prev.fetchFromGitHub {
    owner = "kovidgoyal";
    repo = "kitty";
    rev = "a5322c06d1612535cad782d10efa9732b87cb1b6";
    hash = "sha256-+HuMFLHU8HnRYeeEc5O5rtLHEAKOat+P+i7VClLDRrA=";
  };
in {
  kitty = prev.kitty.overrideAttrs (old: {
    version = "0.46.0-dev";
    src = kittySrc;
    patches = [];
    env = (old.env or {}) // { GOTOOLCHAIN = "local"; };
    goModules = (prev.buildGo124Module {
      pname = "kitty-go-modules";
      version = "0.46.0-dev";
      src = kittySrc;
      vendorHash = "sha256-abvQN11gsanL7vV8dhEJFTMOdBJFtZAxMo+FWbF+s+c=";
      env.GOTOOLCHAIN = "local";
    }).goModules;
  });
}
