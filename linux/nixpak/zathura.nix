{ pkgs, lib, inputs, ... }:
let
  np = import ./lib.nix { inherit pkgs inputs; inherit (pkgs) lib; };
  inherit (np) mkNixPak guiRoBinds commonRoBinds commonDbusPolices;

  sandboxed = mkNixPak {
    config = { sloth, ... }: {
      app.package = pkgs.zathura;
      bubblewrap = {
        network = false;
        sockets.wayland = true;
        bind.ro = [
          (sloth.env "DOCUMENT_DIR")
        ] ++ guiRoBinds sloth ++ commonRoBinds;
        bind.dev = [ "/dev/dri" ];
      };
      gpu.enable = true;
      dbus.enable = true;
      dbus.policies = commonDbusPolices;
    };
  };

  wrapper = pkgs.writeShellScriptBin "zathura" ''
    arg="''${1#file://}"
    file="$(realpath "$arg" 2>/dev/null || echo "$arg")"
    export DOCUMENT_DIR="$(dirname "$file")"
    exec ${sandboxed.config.env}/bin/zathura "$@"
  '';
in {
  home-manager.users.andrei.home.packages = [ (lib.hiPrio wrapper) ];
  home-manager.users.andrei.xdg.desktopEntries.zathura = {
    name = "Zathura";
    comment = "A minimalistic document viewer";
    exec = "${wrapper}/bin/zathura %f";
    icon = "org.pwmt.zathura";
    terminal = false;
    categories = ["Office" "Viewer"];
    mimeType = ["application/pdf" "application/epub+zip" "application/oxps" "application/x-fictionbook"];
  };
}
