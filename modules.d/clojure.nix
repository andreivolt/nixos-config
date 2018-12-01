{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; with wrapped; [
    clojure
    boot
  ];

  systemd.user.services.clojure = {
    wantedBy = [ "default.target" ];
    path = [ pkgs.clojure ];
    script = ''
      clj \
        -Sdeps '{:deps {nrepl {:mvn/version "0.4.5"} cider/cider-nrepl {:mvn/version "0.18.0"}}}' \
        --main nrepl.cmdline \
          --middleware '[cider.nrepl/cider-middleware]' \
          --port 9999'';
    serviceConfig.Restart = "always"; };
}
