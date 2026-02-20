{ pkgs, lib, inputs, ... }:
let
  np = import ./lib.nix { inherit pkgs inputs; inherit (pkgs) lib; };
  inherit (np) mkNixPak guiRoBinds commonRoBinds commonDbusPolices;

  isx86 = pkgs.stdenv.hostPlatform.isx86_64;

  sandboxed = mkNixPak {
    config = { sloth, ... }: {
      app.package = pkgs.spotify;
      bubblewrap = {
        network = true;
        sockets.wayland = true;
        sockets.pulse = true;
        bind.rw = [
          (sloth.concat' sloth.homeDir "/.config/spotify")
          (sloth.concat' sloth.homeDir "/.cache/spotify")
        ];
        bind.ro = guiRoBinds sloth ++ commonRoBinds;
        bind.dev = [ "/dev/dri" ];
      };
      gpu.enable = true;
      dbus.enable = true;
      dbus.policies = commonDbusPolices // {
        "org.mpris.MediaPlayer2.spotify" = "own";
      };
    };
  };
in lib.mkIf isx86 {
  home-manager.users.andrei.xdg.desktopEntries.spotify = {
    name = "Spotify";
    exec = "${sandboxed.config.env}/bin/spotify %U";
    icon = "spotify";
    terminal = false;
    categories = ["Audio" "Music" "Player"];
  };
}
