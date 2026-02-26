{ pkgs, inputs, ... }:
let
  np = import ./lib.nix { inherit pkgs inputs; inherit (pkgs) lib; };
  inherit (np) mkNixPak guiRoBinds commonRoBinds commonDbusPolices;

  sandboxed = mkNixPak {
    config = { sloth, ... }: {
      app.package = pkgs.telegram-desktop;
      bubblewrap = {
        network = true;
        sockets.wayland = true;
        sockets.pulse = true;
        bind.rw = [
          (sloth.concat' sloth.homeDir "/.local/share/TelegramDesktop")
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
in {
  home-manager.users.andrei.home.packages = [ sandboxed.config.env ];
  home-manager.users.andrei.xdg.desktopEntries.telegram = {
    name = "Telegram";
    genericName = "Messaging";
    exec = "${sandboxed.config.env}/bin/Telegram %u";
    icon = "telegram";
    terminal = false;
    categories = ["Network" "InstantMessaging"];
  };
}
