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

    AirServer = self.installApplication rec {
      name = "AirServer";
      version = "7.2.7";
      sourceRoot = "AirServer.app";
      src = super.fetchurl rec {
        name = "AirServer-${version}.dmg";
        url = "https://dl.airserver.com/mac/AirServer-${version}.dmg";
        sha256 = "e092aa4803418483dac749f71c644d63972b4ffe61f235364b92a5b72e08ae0d";
      };
      description = "AirPlay receiver for Mac and PC";
      homepage = "https://www.airserver.com";
    };

    BetterDisplay = self.installApplication rec {
      name = "BetterDisplay";
      version = "2.1.3";
      sourceRoot = "BetterDisplay.app";
      src = super.fetchurl rec {
        name = "BetterDisplay-${version}.dmg";
        url = "https://github.com/waydabber/BetterDisplay/releases/download/v${version}/BetterDisplay-${version}.dmg";
        sha256 = "1bfbcc0b16ad810c933e9ae5f503caa59615943275b7b84060b5b5e4721d5926";
      };
      description = "Display management tool";
      homepage = "https://github.com/waydabber/BetterDisplay";
    };

    ChatTab = self.installApplication rec {
      name = "ChatTab";
      version = "latest";
      sourceRoot = "ChatTab.app";
      src = super.fetchurl rec {
        name = "ChatTab.dmg";
        url = "https://lessstorage.blob.core.windows.net/chattab/ChatTab.dmg";
        sha256 = "31d306b95922e83c73f9a907d67ee4f7519a7ea7290a065286a6ce6184cbf651";
      };
      description = "Chat application";
      homepage = "ChatTab Homepage";
    };

    Downie = self.installApplication rec {
      name = "Downie";
      version = "4.4653";
      sourceRoot = "Downie.app";
      src = super.fetchurl rec {
        name = "Downie_${version}.dmg";
        url = "https://software.charliemonroe.net/trial/downie/v4/Downie_4_4653.dmg";
        sha256 = "ae492cc0451155a08fe23aac29864d7cf7ba7ea95256472c882b1adbae21a737";
      };
      description = "Video downloader for macOS";
      homepage = "https://software.charliemonroe.net/downie/";
    };

    Heynote = self.installApplication rec {
      name = "Heynote";
      version = "1.4.2";
      sourceRoot = "Heynote.app";
      src = super.fetchurl rec {
        name = "Heynote_${version}_universal.dmg";
        url = "https://github.com/heyman/heynote/releases/download/v${version}/Heynote_1.4.2_universal.dmg";
        sha256 = "ef0f7c66bae857d030662504ff68854bd1d2948dbf58e9322441be4c1df89f16";
      };
      description = "Note taking application";
      homepage = "https://github.com/heyman/heynote";
    };

    IntelliBar = self.installApplication rec {
      name = "IntelliBar";
      version = "0.16.0";
      sourceRoot = "IntelliBar.app";
      src = super.fetchurl rec {
        name = "IntelliBar-${version}-arm64.dmg";
        url = "https://github.com/intellibar/main/releases/download/0.16.0/IntelliBar-0.16.0-arm64.dmg";
        sha256 = "c2156922796183a6213fefce8109f2c4c67b0c09e61874521f0ea9c43aeb0cde";
      };
      description = "Intelligent toolbar for macOS";
      homepage = "https://github.com/intellibar/main";
    };

    Kit = self.installApplication rec {
      name = "Kit";
      version = "2.0.42";
      sourceRoot = "Kit.app";
      src = super.fetchurl rec {
        name = "Kit-macOS-${version}-arm64.dmg";
        url = "https://github.com/johnlindquist/kitapp/releases/download/v${version}/Kit-macOS-2.0.42-arm64.dmg";
        sha256 = "5caf4603580e538a08eba2b63ad9968f76bd680a37e10f7458a8575dd14f3f19";
      };
      description = "Scripting environment for developers";
      homepage = "https://github.com/johnlindquist/kitapp";
    };

    Orion = self.installApplication rec {
      name = "Orion";
      version = "14.0"; # Update version if known
      sourceRoot = "Orion.app";
      src = super.fetchurl rec {
        name = "Orion.dmg";
        url = "https://cdn.kagi.com/downloads/14_0/Orion.dmg";
        sha256 = "7f079223249dfcb0436bf9568c9d6f97ae76cca4925e1b8903221d2f5eb2da48";
      };
      description = "Web browser";
      homepage = "https://www.kagi.com";
    };

    PathFinder = self.installApplication rec {
      name = "PathFinder";
      version = "latest";  # Update version if known
      sourceRoot = "PathFinder.app";
      src = super.fetchurl rec {
        name = "PathFinder.dmg";
        url = "https://get.cocoatech.com/PathFinder.dmg";
        sha256 = "4738fad569deef4dabddcbee30822fe0fc4a5cf97c18c8df677036891fd9bce8";
      };
      description = "File management application";
      homepage = "https://cocoatech.com/";
    };

    PrettyClean = self.installApplication rec {
      name = "PrettyClean";
      version = "0.1.38";
      sourceRoot = "PrettyClean.app";
      src = super.fetchurl rec {
        name = "PrettyClean_${version}_aarch64.dmg";
        url = "https://downloads.jmotor.org/prettyclean/v0.1.38/darwin-aarch64/PrettyClean_0.1.38_aarch64.dmg";
        sha256 = "1832d6ffdbe0fcbffe35c3b2f6ac4031e7e8ce93a7c564124914888ebfb43885";
      };
      description = "System cleaning tool";
      homepage = "PrettyClean Homepage URL";  # Update URL
    };

    Telegram = self.installApplication rec {
      name = "Telegram";
      version = "latest";  # Update version if known
      sourceRoot = "Telegram.app";
      src = super.fetchurl rec {
        name = "Telegram.dmg";
        url = "https://osx.telegram.org/updates/Telegram.dmg";
        sha256 = "04a9d3a57976594d0d21c6bec71d48af7a7113baccd001f4b72078f69f28b27a";
      };
      description = "Messaging application";
      homepage = "https://telegram.org";
    };

    WriteMage = self.installApplication rec {
      name = "WriteMage";
      version = "latest";  # Update version if known
      sourceRoot = "WriteMage.app";
      src = super.fetchurl rec {
        name = "WriteMage.dmg";
        url = "https://magic.writemage.com/WriteMage.dmg";
        sha256 = "d60eeaafa6a64c91d5b61d449151481c9ced5611ff2db0d28f9552b49330ff39";
      };
      description = "Writing tool";
      homepage = "WriteMage Homepage URL";  # Update URL
    };

    macpilot = self.installApplication rec {
      name = "macpilot";
      version = "latest";  # Update version if known
      sourceRoot = "macpilot.app";
      src = super.fetchurl rec {
        name = "macpilot.dmg";
        url = "https://www.koingosw.com/products/macpilot/download/macpilot.dmg";
        sha256 = "15ee0552eab36bef59c3baed3415bb12aae557cf00a5e8c11e58717705aba036";
      };
      description = "System utility tool";
      homepage = "https://www.koingosw.com/products/macpilot/";
    };

    superwhisper = self.installApplication rec {
      name = "superwhisper";
      version = "latest";  # Update version if known
      sourceRoot = "superwhisper.app";
      src = super.fetchurl rec {
        name = "superwhisper.dmg";
        url = "https://builds.superwhisper.com/latest/superwhisper.dmg";
        sha256 = "400d7fee468e84a7ea29a288cce8567c82969f288edebd2c19039d6e0ac24027";
      };
      description = "Superwhisper Description";  # Update description
      homepage = "Superwhisper Homepage URL";  # Update URL
    };
  }
