{ config, lib, pkgs, ... }:

let
  shims = [
    "files-to-prompt"
    "ttok"
    { pkg = "llm"; withPackages = "llm-anthropic,llm-gemini"; }
  ];

  shimDir = "\${HOME}/.local/bin/uvx-shims";

  createShim = shim:
    let
      shimData = if builtins.isString shim then { pkg = shim; } else shim;
      exe = shimData.exe or shimData.pkg;
    in ''
    mkdir -p ${shimDir}
    cat > ${shimDir}/${exe} << 'EOF'
    #!/bin/sh
    ${if shimData ? withPackages then
      "exec uvx --quiet --with ${shimData.withPackages} ${shimData.pkg} \"$@\""
    else
      "exec uvx --quiet ${shimData.pkg} \"$@\""
    }
    EOF
    chmod +x ${shimDir}/${exe}
  '';

in {
  home-manager.users.andrei.programs.zsh.initContent = ''
    ${lib.concatMapStringsSep "\n" createShim shims}
    export PATH="${shimDir}:$PATH"
  '';
}
