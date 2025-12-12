{ iosevka }:

# Custom Iosevka build with Berkeley Mono-inspired aesthetics
# Goals: compact, geometric, sleek, highly readable at small sizes
(iosevka.override {
  set = "Sleek";
  privateBuildPlan = {
    family = "Iosevka Sleek";
    spacing = "term";           # Tightest spacing for compact feel
    serifs = "sans";            # Clean sans-serif
    noCvSs = false;             # Include stylistic sets
    exportGlyphNames = false;   # Smaller file size

    # Slightly narrower for compact look
    widths.Normal = {
      shape = 500;              # Default is 500
      menu = 5;
      css = "normal";
    };

    # Character variants for geometric, clean aesthetic
    variants.design = {
      # Numerals - clean and geometric
      zero = "dotted";          # Dotted zero for clarity
      one = "no-serif";         # Clean 1 without serifs
      four = "closed";          # Closed 4 for geometric look
      six = "closed-contour";   # Rounded 6
      nine = "closed-contour";  # Rounded 9

      # Lowercase - single-storey for cleaner look
      a = "single-storey-serifless";
      g = "single-storey-serifless";

      # Geometric lowercase
      i = "serifless";          # Clean i without serif
      l = "serifless";          # Clean l without serif
      j = "serifless";          # Clean j
      t = "flat-hook";          # Flat hook on t
      f = "flat-hook-serifless"; # Flat hook on f
      r = "serifless";          # Simple r
      u = "toothless-corner";   # Clean u

      # Clean uppercase
      capital-i = "short-serifed"; # I with subtle serifs for clarity
      capital-j = "serifless";
      capital-g = "toothless-corner";
      capital-q = "crossing";   # Q with crossing tail

      # Symbols - clean and minimal
      asterisk = "hex-low";     # Low asterisk
      at = "compact";           # Compact @
      ampersand = "closed";     # Closed &
      percent = "dots";         # Dots for % (cleaner)
      paren = "normal";
      brace = "straight";       # Straight braces
      number-sign = "upright";  # Upright #
      question = "smooth";      # Smooth ?

      # Punctuation
      period = "round";
      comma = "round";

      # Other
      dollar = "open";          # Open $
      cent = "open";            # Open cent
      lig-ltgteq = "flat";      # Flat comparison operators
    };

    # Ligatures - minimal set for code readability
    ligations = {
      inherits = "dlig";        # Only discretionary ligatures
    };
  };
})
