# Build kitty from fork with graphical progress bar for OSC 9;4
inputs: final: prev: let
  kittySrc = prev.fetchFromGitHub {
    owner = "andreivolt";
    repo = "kitty";
    rev = "3ddaf56";
    hash = "sha256-bQ4szhYw6nkTRtZ2cXfO/p22coI4rbPzYO783NTS3M8=";
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
