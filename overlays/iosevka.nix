self: pkgs: rec {

iosevka-custom = pkgs.iosevka.override {
  set = "custom";
  weights = [
    "light"
  ];
  design = [
    "termlig"
    "v-asterisk-low"
    "v-at-short"
    "v-i-zshaped"
    "v-tilde-low"
    "v-underscore-low"
    "v-zero-dotted"
    "v-zshaped-l"
  ];
};

}
