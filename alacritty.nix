{ theme, monospaceFont, fontSize }:

''
dpi:
  x: 96.0
  y: 96.0

tabspaces: 4

draw_bold_text_with_bright_colors: true

font:
  normal:
    family: ${monospaceFont}
    style: Regular
  bold:
    family: ${monospaceFont}
    style: Bold
  italic:
    family: ${monospaceFont}
    style: Italic
  size: ${fontSize}
  offset:
    x: 0.0
    y: -2.0
  glyph_offset:
    x: 0.0
    y: 0.0

custom_cursor_colors: true

window:
  padding:
    x: 28
    y: 20
  dimensions:
    columns: 0
    lines: 0

background_opacity: 0.88

colors:
  primary:
    background: '${theme.background}'
    foreground: '${theme.foreground}'

  cursor:
    text:       '${theme.white}'
    cursor:     '${theme.white}'

  normal:
    black:      '${theme.black}'
    white:      '${theme.white}'
    blue:       '${theme.blue}'
    cyan:       '${theme.cyan}'
    green:      '${theme.green}'
    grey:       '${theme.gray}'
    magenta:    '${theme.magenta}'
    red:        '${theme.red}'
    yellow:     '${theme.yellow}'

  bright:
    black:      '${theme.gray}'
    white:      '${theme.white}'
    blue:       '${theme.lightBlue}'
    cyan:       '${theme.lightCyan}'
    green:      '${theme.lightGreen}'
    grey:       '${theme.lightGray}'
    magenta:    '${theme.lightMagenta}'
    red:        '${theme.lightRed}'
    yellow:     '${theme.lightYellow}'

# dim:
#   black:   '0x333333'
#   red:     '0xf2777a'
#   green:   '0x99cc99'
#   yellow:  '0xffcc66'
#   blue:    '0x6699cc'
#   magenta: '0xcc99cc'
#   cyan:    '0x66cccc'
#   white:   '0xdddddd'

visual_bell:
  duration: 0

selection:
  semantic_escape_chars: ",│`|:\"' ()[]{}<>"

hide_cursor_when_typing: false

key_bindings:
  - { key: V,        mods: Control|Shift,    action: Paste            }
  - { key: C,        mods: Control|Shift,    action: Copy             }
  - { key: Q,        mods: Command,          action: Quit             }
  - { key: W,        mods: Command,          action: Quit             }
  - { key: Insert,   mods: Shift,            action: Paste            }
  - { key: Key0,     mods: Control,          action: ResetFontSize    }
  - { key: Equals,   mods: Control,          action: IncreaseFontSize }
  - { key: Subtract, mods: Control,          action: DecreaseFontSize }
''
