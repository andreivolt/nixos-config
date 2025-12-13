# Python scripts using uv2nix with PEP-723 inline metadata
# Each .py file in this directory should have inline dependencies like:
#   # /// script
#   # requires-python = ">=3.12"
#   # dependencies = ["requests", "click"]
#   # ///
{
  lib,
  pkgs,
  uv2nix,
  pyproject-nix,
  pyproject-build-systems,
}:
let
  # Load all Python scripts from this directory
  scriptFiles = lib.filterAttrs
    (name: type: type == "regular" && lib.hasSuffix ".py" name)
    (builtins.readDir ./.);

  scripts = lib.mapAttrs
    (name: _:
      uv2nix.lib.scripts.loadScript {
        script = ./. + "/${name}";
      }
    )
    scriptFiles;

  python = pkgs.python3;
  baseSet = pkgs.callPackage pyproject-nix.build.packages {
    inherit python;
  };

  buildScript = name: script:
    let
      overlay = script.mkOverlay {
        sourcePreference = "wheel";
      };

      pythonSet = baseSet.overrideScope (
        lib.composeManyExtensions [
          pyproject-build-systems.overlays.wheel
          overlay
        ]
      );
    in
    pkgs.writeScript (lib.removeSuffix ".py" name) (
      script.renderScript {
        venv = script.mkVirtualEnv {
          inherit pythonSet;
        };
      }
    );

in
lib.mapAttrs' (name: script:
  lib.nameValuePair (lib.removeSuffix ".py" name) (buildScript name script)
) scripts
