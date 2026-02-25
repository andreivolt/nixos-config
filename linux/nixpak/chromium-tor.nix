{ pkgs, lib, config, inputs, ... }:
let
  np = import ./lib.nix { inherit pkgs inputs; inherit (pkgs) lib; };
  inherit (np) mkNixPak guiRoBinds commonRoBinds commonDbusPolices;

  args = config.chromium.baseArgs ++ [
    "--proxy-server=socks5://127.0.0.1:9050"
    "--no-first-run"
    "--no-default-browser-check"
  ];

  extensionIds = import ../../shared/chromium/chrome-extensions.nix;

  policy = pkgs.writeTextDir "managed/policy.json" (builtins.toJSON {
    JavaScriptBlockedForUrls = [ "[*.]onion" ];
    ExtensionInstallForcelist = map
      (id: "${id};https://clients2.google.com/service/update2/crx")
      extensionIds;
  });

  inner = pkgs.writeShellScriptBin "chromium-tor" ''
    datadir="$XDG_RUNTIME_DIR/chromium-tor"
    mkdir -p "$datadir"
    exec ${pkgs.chromium}/bin/chromium \
      ${lib.escapeShellArgs args} \
      "--user-data-dir=$datadir" "$@"
  '';

  sandboxed = mkNixPak {
    config = { sloth, ... }: {
      app.package = inner;
      app.binPath = "bin/chromium-tor";
      bubblewrap = {
        network = true;
        sockets.wayland = true;
        sockets.pulse = true;
        bind.rw = [
          (sloth.concat' (sloth.env "XDG_RUNTIME_DIR") "/chromium-tor")
          "/dev/shm"
        ];
        bind.ro = [
          ["${policy}" "/etc/chromium/policies"]
        ] ++ guiRoBinds sloth ++ commonRoBinds;
        bind.dev = [ "/dev/dri" ];
        tmpfs = [ "/tmp" ];
      };
      gpu.enable = true;
      dbus.enable = true;
      dbus.policies = commonDbusPolices;
    };
  };

  wrapper = pkgs.writeShellScript "chromium-tor-sandboxed" ''
    mkdir -p "$XDG_RUNTIME_DIR/chromium-tor"
    exec ${sandboxed.config.env}/bin/chromium-tor "$@"
  '';
in {
  home-manager.users.andrei.xdg.desktopEntries.chromium-tor = {
    name = "Chromium (Tor)";
    genericName = "Web Browser";
    exec = "${wrapper} %U";
    icon = "chromium";
    terminal = false;
    categories = ["Network" "WebBrowser"];
    actions = {
      "new-window" = {
        name = "New Window";
        exec = "${wrapper}";
      };
      "new-private-window" = {
        name = "New Incognito Window";
        exec = "${wrapper} --incognito";
      };
    };
  };
}
