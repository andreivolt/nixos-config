{ pkgs, lib, inputs, ... }:
let
  np = import ./lib.nix { inherit pkgs inputs; inherit (pkgs) lib; };
  inherit (np) mkNixPak guiRoBinds commonRoBinds;

  sandboxed = mkNixPak {
    config = { sloth, ... }: {
      app.package = pkgs.swayimg;
      bubblewrap = {
        network = false;
        sockets.wayland = true;
        bind.ro = [
          (sloth.env "IMAGE_DIR")
          (sloth.concat' sloth.homeDir "/.config/swayimg")
        ] ++ guiRoBinds sloth ++ commonRoBinds;
        bind.dev = [ "/dev/dri" ];
      };
      gpu.enable = true;
    };
  };

  wrapper = pkgs.writeShellScriptBin "swayimg" ''
    arg="''${1#file://}"
    file="$(realpath "$arg" 2>/dev/null || echo "$arg")"
    export IMAGE_DIR="$(dirname "$file")"
    exec ${sandboxed.config.env}/bin/swayimg "$@"
  '';
in {
  home-manager.users.andrei.home.packages = [ (lib.hiPrio wrapper) ];
  home-manager.users.andrei.xdg.desktopEntries.swayimg = {
    name = "Swayimg";
    comment = "Image viewer for Wayland";
    exec = "${wrapper}/bin/swayimg %f";
    icon = "swayimg";
    terminal = false;
    categories = ["Graphics" "Viewer"];
    mimeType = ["image/jpeg" "image/png" "image/gif" "image/bmp" "image/webp" "image/avif" "image/heic" "image/heif" "image/tiff" "image/svg+xml"];
  };
}
