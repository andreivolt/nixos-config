{ iosevka }:

# Custom Iosevka build with Berkeley Mono-inspired aesthetics
# Goals: compact, geometric, sleek, highly readable at small sizes
# Uses SS14 (JetBrains Mono style) as base for clean geometric look
(iosevka.override {
  set = "Sleek";
  privateBuildPlan = {
    family = "Iosevka Sleek";
    spacing = "term";           # Tightest spacing for compact feel
    serifs = "sans";            # Clean sans-serif
    noCvSs = false;
    exportGlyphNames = false;

    # Inherit from JetBrains Mono style - clean and geometric
    variants.inherits = "ss14";
  };
})
