{ pkgs, lib, inputs, ... }:
let
  np = import ./lib.nix { inherit pkgs inputs; inherit (pkgs) lib; };
  inherit (np) mkNixPak guiRoBinds commonRoBinds commonDbusPolices;

  isx86 = pkgs.stdenv.hostPlatform.isx86_64;

  sandboxed = mkNixPak {
    config = { sloth, ... }: {
      app.package = pkgs.discord;
      bubblewrap = {
        network = true;
        sockets.wayland = true;
        sockets.pulse = true;
        bind.rw = [
          (sloth.concat' sloth.homeDir "/.config/discord")
          (sloth.concat' sloth.homeDir "/Downloads")
        ];
        bind.ro = guiRoBinds sloth ++ commonRoBinds;
        bind.dev = [ "/dev/dri" ];
      };
      gpu.enable = true;
      dbus.enable = true;
      dbus.policies = commonDbusPolices;
    };
  };
in lib.mkIf isx86 {
  home-manager.users.andrei.home.packages = [ sandboxed.config.env ];
  home-manager.users.andrei.xdg.desktopEntries.discord = {
    name = "Discord";
    exec = "${sandboxed.config.env}/bin/Discord %U";
    icon = "discord";
    terminal = false;
    categories = ["Network" "InstantMessaging"];
  };
}
