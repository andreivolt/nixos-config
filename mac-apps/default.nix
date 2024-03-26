self: super:
let
  installApplication =
    { name
    , appname ? name
    , version
    , src
    , description ? ""
    , homepage ? ""
    , postInstall ? ""
    , sourceRoot ? "."
    , ...
    }@args:
    super.stdenv.mkDerivation ({
      inherit name version src sourceRoot;
      buildInputs = with super; [ undmg unzip ];

      unpackPhase = ''
        if [[ "${src}" == *.dmg ]]; then
          if ! undmg $src; then
            # fallback to hdiutil if undmg fails
            TMPDIR=$(mktemp -d)
            /usr/bin/hdiutil attach $src -nobrowse -mountpoint $TMPDIR
            echo "Mounted at $TMPDIR"
            # Assuming the .app is directly in the mounted volume
            cp -r $TMPDIR/*.app .
            /usr/bin/hdiutil detach $TMPDIR
          fi
        else
          # Fallback to default unpack for non-DMG sources
          unpackCmds
        fi
      '';

      installPhase = ''
        mkdir -p "$out/Applications/${appname}.app"
        cp -R * "$out/Applications/${appname}.app"
      '' + postInstall;
    } // super.lib.optionalAttrs (args ? description) { meta = { inherit description homepage; }; });
in
{
  macApps = super.lib.attrsets.mapAttrs'
    (appName: _: {
      name = super.lib.strings.removeSuffix ".nix" appName;
      value = import ./apps/${appName} {
        inherit installApplication;
        inherit (super) fetchurl;
      };
    })
    (builtins.readDir ./apps);
}
