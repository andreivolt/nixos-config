{ colors }:
let
  aurora = colors.aurora;
in {
  foreground = aurora.foreground;
  background = aurora.background;
  cursor-color = aurora.cursor;
  cursor-text = aurora.cursorText;
  selection-background = aurora.selection.background;
  selection-foreground = aurora.selection.foreground;

  palette = [
    "0=${aurora.normal.black}"
    "1=${aurora.normal.red}"
    "2=${aurora.normal.green}"
    "3=${aurora.normal.yellow}"
    "4=${aurora.normal.blue}"
    "5=${aurora.normal.magenta}"
    "6=${aurora.normal.cyan}"
    "7=${aurora.normal.white}"
    "8=${aurora.bright.black}"
    "9=${aurora.bright.red}"
    "10=${aurora.bright.green}"
    "11=${aurora.bright.yellow}"
    "12=${aurora.bright.blue}"
    "13=${aurora.bright.magenta}"
    "14=${aurora.bright.cyan}"
    "15=${aurora.bright.white}"
    "16=${aurora.extended.color16}"
    "17=${aurora.extended.color17}"
  ];
}
