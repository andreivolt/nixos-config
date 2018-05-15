self: pkgs: rec {

iosevka-custom = with pkgs; stdenv.lib.overrideDerivation
  (pkgs.iosevka.override {
    set = "custom";
    weights = [
      "bold"
      "book"
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
  }) (attrs: {
    preConfigure = attrs.preConfigure + ''
      cp ${./parameters.toml} parameters.toml
    '';
  });

}
