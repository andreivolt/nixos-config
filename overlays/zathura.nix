self: pkgs: rec {

zathura = pkgs.zathura.override {
  useMupdf = true;
};

}
