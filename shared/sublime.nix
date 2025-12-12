{pkgs, ...}: let
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
in {
  home-manager.sharedModules = [
    {
      xdg.configFile = {
        "sublime-text/Packages/User/Preferences.sublime-settings".source = ./sublime/Preferences.sublime-settings;
        "sublime-text/Packages/User/Package Control.sublime-settings".source = ./sublime/Package\ Control.sublime-settings;
        "sublime-text/Packages/AutoDarkLinux".source = autodark-sublime;
      };
    }
  ];
}
