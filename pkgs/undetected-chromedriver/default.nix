{
  python3,
}:
python3.withPackages (ps:
    with ps; [
      (buildPythonPackage rec {
        pname = "undetected-chromedriver";
        version = "3.5.4";
        pyproject = true;

        buildInputs = [setuptools];

        src = fetchPypi {
          inherit pname version;
          hash = "sha256-le/dh53fjyou/2kZ+jGM00wIC9B/uBrgzbeUnAFColg=";
        };
      })
    ])
# # based on
# # nixpkgs/pkgs/development/tools/selenium/chromedriver/default.nix
# # https://github.com/ultrafunkamsterdam/undetected-chromedriver
# # note: chromedriver must have the same major version as chromium
# { lib
# , stdenv
# , chromedriver
# }:
# let
#   allSpecs = {
#     x86_64-linux = {
#       system = "linux64";
#     };
#     x86_64-darwin = {
#       system = "mac-x64";
#     };
#     aarch64-darwin = {
#       system = "mac-arm64";
#     };
#   };
#   spec = allSpecs.${stdenv.hostPlatform.system}
#     or (throw "missing chromedriver binary for ${stdenv.hostPlatform.system}");
# in
# chromedriver.overrideAttrs (oldAttrs: rec {
#   pname = "undetected-chromedriver";
#   # patch this function:
#   # (function () {window.cdc_adoQpoasnfa76pfcZLmcfl_Array = window.Array;...
#   # ...;}).apply({navigator:
#   # a: window.cdc_adoQpoasnfa76pfcZLmcfl_Array = window.Array;
#   # b: return;"undetected chromedriver";_Array = window.Array;
#   # the string "undetected chromedriver" is expected by undetected_chromedriver/patcher.py
#   # this is valid javascript: (function() { return; ""; })()
#   # based on https://github.com/ultrafunkamsterdam/undetected-chromedriver
#   # note: chromedriver has no buildPhase
#   # TODO assert
#   buildPhase = ''
#     runHook preBuild
#     echo patching chromedriver
#     sed -i.bak -E \
#       's/\(function \(\) \{window.cdc_[a-zA-Z0-9]{22}/(function () {return;"undetected chromedriver";/' \
#       "chromedriver-${spec.system}/chromedriver"
#     if [[
#       "$(md5sum "chromedriver-${spec.system}/chromedriver" | cut -c1-32)" == \
#       "$(md5sum "chromedriver-${spec.system}/chromedriver.bak" | cut -c1-32)"
#     ]]; then
#       echo "error: failed to patch chromedriver"
#       echo "------------ match --------------"
#       grep -a -o -m1 -E '\(function \(\) \{window\.cdc_.{22}.{100}' "chromedriver-${spec.system}/chromedriver" ||
#       echo "error: no match"
#       echo "---------------------------------"
#       exit 1
#     fi
#     rm "chromedriver-${spec.system}/chromedriver.bak"
#     runHook postBuild
#   '';
# })
# { lib
# , fetchFromGitHub
# , pkgs-undetected-chromedriver
# # python3.pkgs
# , buildPythonApplication
# , setuptools
# , wheel
# , requests
# , certifi
# , websockets
# , selenium
# }:
# buildPythonApplication rec {
#   pname = "undetected-chromedriver";
#   # https://pypi.org/project/undetected-chromedriver/
#   version = "3.5.4";
#   pyproject = true;
#   passthru = {
#     # patched chromedriver binary
#     # usage:
#     /*
#       undetected_chromedriver.Chrome(
#         driver_executable_path="/path/to/chromedriver",
#         driver_executable_is_patched=True,
#       )
#     */
#     bin = pkgs-undetected-chromedriver;
#   };
#   src = fetchFromGitHub {
#     /*
#     owner = "ultrafunkamsterdam";
#     repo = "undetected-chromedriver";
#     rev = "783b8393157b578e19e85b04d300fe06efeef653";
#     hash = "sha256-vQ66TAImX0GZCSIaphEfE9O/wMNflGuGB54+29FiUJE=";
#     */
#     # setup.py: import version
#     # https://github.com/ultrafunkamsterdam/undetected-chromedriver/pull/1686
#     # add parameter driver_executable_is_patched
#     # https://github.com/ultrafunkamsterdam/undetected-chromedriver/pull/1687
#     owner = "ultrafunkamsterdam";
#     repo = "undetected-chromedriver";
#     rev = "52c80c160b747b067d14a73908ca5c0e9d3eb15a";
#     hash = "sha256-42ETV3VFI4E3vNeVxovGxTr5KPFVyFlrhA7wmVVHM94=";
#   };
#   nativeBuildInputs = [
#     setuptools
#     wheel
#   ];
#   propagatedBuildInputs = [
#     requests
#     certifi
#     websockets
#     selenium
#   ];
#   pythonImportsCheck = [ "undetected_chromedriver" ];
#   meta = with lib; {
#     description = "Custom Selenium Chromedriver | Zero-Config | Passes ALL bot mitigation systems (like Distil / Imperva/ Datadadome / CloudFlare IUAM";
#     homepage = "https://github.com/ultrafunkamsterdam/undetected-chromedriver";
#     license = licenses.gpl3Only;
#     maintainers = with maintainers; [ ];
#   };
# }

