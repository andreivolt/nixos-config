{ config, pkgs, ... }:

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
          --port 9999
    '';
    serviceConfig.Restart = "always";
  };

  systemd.user.services.emacs-clojure = {
    wantedBy = [ "default.target" ];
    path = [ pkgs.avo.emacs-clojure ];
    script = "source ${config.system.build.setEnvironment} && emacs-clojure_server";
    serviceConfig.Restart = "always";
  };

  # environment.variables.CLJ_CONFIG = let _ = ''
  #   {:aliases {:find-deps {:extra-deps
  #                           {find-deps
  #                              {:git/url "https://github.com/hagmonk/find-deps",
  #                               :sha "6fc73813aafdd2288260abb2160ce0d4cdbac8be"}},
  #                          :main-opts ["-m" "find-deps.core"]}}}
  # ''; in "${pkgs.writeText "_" _}";
}
