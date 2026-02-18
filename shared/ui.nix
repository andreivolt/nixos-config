# Central UI size definitions
#
# fontSizePx: canonical size in CSS logical pixels (used by Ironbar CSS)
# fontSizePt: same visual size in points for GTK/Pango/Qt (px × 72/96)
#
# Hyprland groupbar/hyprbars use Pango points, so fontSizePt gives the
# same apparent size as fontSizePx in GTK CSS contexts.
{
  fontSizePx = 14;
  fontSizePt = 11; # 14 × 0.75 ≈ 10.5 → 11
  fontFamily = "Inter";
}
