{inputs, ...}: {
  homebrew = {
    enable = true;

    onActivation = {
      cleanup = "zap";
      autoUpdate = true;
      upgrade = true;
    };

    caskArgs = {
      no_quarantine = true;
      # require_sha = true;
    };

    brews = import "${inputs.self}/homebrew-brews.nix";
    casks = import "${inputs.self}/homebrew-casks.nix";
    masApps = import "${inputs.self}/homebrew-masapps.nix";
    taps = [
      "homebrew/bundle"
      "homebrew/cask-versions"
      "homebrew/command-not-found"
      "homebrew/services"
      "jakehilborn/jakehilborn"
    ];
  };
}