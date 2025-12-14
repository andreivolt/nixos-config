{pkgs, ...}: let
  # Helper to fetch a sublime package from GitHub
  fetchSublimePackage = {name, owner, repo, sha256}: pkgs.fetchFromGitHub {
    inherit owner repo sha256;
    rev = "refs/heads/master";
  };

  # AutoDarkLinux with NixOS patch
  autodark-sublime = pkgs.stdenv.mkDerivation {
    pname = "autodark-sublime-plugin";
    version = "1.0.3";
    src = pkgs.fetchFromGitHub {
      owner = "smac89";
      repo = "autodark-sublime-plugin";
      rev = "7365279e61ca437edbfeaa94e44bdb6d8a826500";
      sha256 = "0rb40dw5p2im6grmd0fhmhxly414jhfyj1v9zjsyj4745a48d6rv";
    };
    patches = [./sublime/autodark-nixos.patch];
    installPhase = ''
      mkdir -p $out
      cp -r . $out/
    '';
  };

  # All sublime packages
  packages = {
    NeoVintageous = fetchSublimePackage {
      name = "NeoVintageous";
      owner = "NeoVintageous";
      repo = "NeoVintageous";
      sha256 = "041r6bpx87gayphxbkslx639dvd0ix63m7qvbzw8sicyizmrmra4";
    };
    "Tomorrow Color Schemes" = fetchSublimePackage {
      name = "Tomorrow Color Schemes";
      owner = "theymaybecoders";
      repo = "sublime-tomorrow-theme";
      sha256 = "0sc9z9nijcg7qma966b93rilkmz8vwm94wywqf4hpmdsdxssrcpi";
    };
    distractionless = fetchSublimePackage {
      name = "distractionless";
      owner = "jrappen";
      repo = "sublime-distractionless";
      sha256 = "1w2pjwr6myld03ihajzbp19k01wpgxv4dn11hg4kszxd3ry44k84";
    };
    Moonlight = fetchSublimePackage {
      name = "Moonlight";
      owner = "mauroreisvieira";
      repo = "moonlight-sublime-theme";
      sha256 = "0nv3dnl9grkq58j2c83lfdr1d46jlip2ybyz54hm2maa2c09fwh7";
    };
    SublimeREPL = fetchSublimePackage {
      name = "SublimeREPL";
      owner = "wuub";
      repo = "SublimeREPL";
      sha256 = "119m14iha0lxcjqkwff5fdjnd28cy3pij69j5c0770wsry4x6v4h";
    };
    "Theme - Vim Blackboard" = fetchSublimePackage {
      name = "Theme - Vim Blackboard";
      owner = "oubiwann";
      repo = "vim-blackboard-sublime-theme";
      sha256 = "1xhszblqbl61kfllc059nf11s44jq65iyhzn3vhm4mrgm0gv98x3";
    };
    "Color Scheme - Vintage Terminal" = fetchSublimePackage {
      name = "Color Scheme - Vintage Terminal";
      owner = "tonylegrone";
      repo = "terminal-sublime";
      sha256 = "1qng3rd6in3lvmi15nck918b6hc3n9s8i9kgdsg2n29almz9kdzb";
    };
    "Tomorrow Night Italics Color Scheme" = fetchSublimePackage {
      name = "Tomorrow Night Italics Color Scheme";
      owner = "not-kennethreitz";
      repo = "sublime-tomorrow-night-italics-theme";
      sha256 = "0fhjmbgldgz0m9ayi4lqx2kg2m2a2c8gr881ln98kipwswwfwqxx";
    };
  };

  # Generate xdg.configFile entries for all packages
  packageConfigs = builtins.mapAttrs (name: src: {
    source = src;
  }) packages;
in {
  home-manager.sharedModules = [
    {
      xdg.configFile = {
        # User settings
        "sublime-text/Packages/User/Preferences.sublime-settings".source = ./sublime/Preferences.sublime-settings;
        "sublime-text/Packages/User/Distraction Free.sublime-settings".source = ./sublime + "/Distraction Free.sublime-settings";

        # Packages from git
        "sublime-text/Packages/AutoDarkLinux".source = autodark-sublime;
        "sublime-text/Packages/NeoVintageous".source = packages.NeoVintageous;
        "sublime-text/Packages/Tomorrow Color Schemes".source = packages."Tomorrow Color Schemes";
        "sublime-text/Packages/distractionless".source = packages.distractionless;
        "sublime-text/Packages/Moonlight".source = packages.Moonlight;
        "sublime-text/Packages/SublimeREPL".source = packages.SublimeREPL;
        "sublime-text/Packages/Theme - Vim Blackboard".source = packages."Theme - Vim Blackboard";
        "sublime-text/Packages/Color Scheme - Vintage Terminal".source = packages."Color Scheme - Vintage Terminal";
        "sublime-text/Packages/Tomorrow Night Italics Color Scheme".source = packages."Tomorrow Night Italics Color Scheme";
      };
    }
  ];
}
