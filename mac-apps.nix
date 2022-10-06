self: super: {

installApplication =
  { name, appname ? name, version, src, description, homepage,
    postInstall ? "", sourceRoot ? ".", ... }:
  with super; stdenv.mkDerivation {
    name = "${name}-${version}";
    version = "${version}";
    src = src;
    buildInputs = [ undmg unzip ];
    sourceRoot = sourceRoot;
    phases = [ "unpackPhase" "installPhase" ];
    installPhase = ''
      mkdir -p "$out/Applications/${appname}.app"
      cp -pR * "$out/Applications/${appname}.app"
    '' + postInstall;
  };

  Hyperbeam = self.installApplication rec {
    name = "Hyperbeam";
    version = "0.21.0";
    sourceRoot = "Hyperbeam.app";
    src = super.fetchurl rec {
      name = "Hyperbeam-${version}.dmg";
      url = "https://cdn.hyperbeam.com/${name}";
      sha256 = "sha256-nPGPwjPvnxNq2n9NCiyT+8rivXh/qAtp0X9ItHnxBBI=";
    };
    description = "";
    homepage = https://example.com;
  };

  Firefox = self.installApplication rec {
    name = "Firefox";
    version = "65.0.1";
    sourceRoot = "Firefox.app";
    src = super.fetchurl {
      name = "Firefox-${version}.dmg";
      url = "https://download-installer.cdn.mozilla.net/pub/firefox/releases/${version}/mac/en-GB/Firefox%20${version}.dmg";
      sha256 = "0rc9llndc03ns69v5f94g83f88qav0djv6lw47l47q5w2lpckzv9";
    };
    description = "Free and open-source web browser developed by Mozilla Foundation";
    homepage = https://www.mozilla.org/en-US/firefox;
  };

  iTerm2 = self.installApplication rec {
    inherit (builtins) replaceStrings;
    name = "iTerm2";
    appname = "iTerm";
    version = "3.2.6";
    sourceRoot = "iTerm.app";
    src = super.fetchurl {
    url = "https://iterm2.com/downloads/stable/iTerm2-${replaceStrings ["\."] ["_"] version}.zip";
      sha256 = "116qmdcbbga8hr9q9n1yqnhrmmq26l7pb5lgvlgp976yqa043i6v";
    };
    description = "iTerm2 is a replacement for Terminal and the successor to iTerm";
    homepage = https://www.iterm2.com;
  };

  Rocket = self.installApplication rec {
    name = "Rocket";
    appname = "Rocket";
    version = "1.4";
    sourceRoot = "Rocket.app";
    src = super.fetchurl {
      url = https://dl.devmate.com/net.matthewpalmer.Rocket/Rocket.dmg;
      sha256 = "CbIT0Q9ZMjhosnV6VbshJRH9HvRr35htelFOVQC42+4=";
    };
    description = "Mind-blowing emoji on your Mac";
    homepage = https://matthewpalmer.net/rocket/;
  };
}
