{ theme }:

with theme;

''
  set termguicolors

  for i in [ 'Keyword', 'Boolean', 'Character', 'Comment', 'Conceal', 'Conditional', 'Constant', 'Cursor', 'Cursor2', 'CursorLine', 'Debug', 'Define', 'Delimiter', 'Directory', 'Error', 'ErrorMsg', 'Exception', 'Float', 'FoldColumn', 'Function', 'Identifier', 'Ignore', 'Include', 'IncSearch', 'Keyword', 'Label', 'Macro', 'MatchParen', 'Normal', 'Number', 'Operator', 'PreCondit', 'PreProc', 'Repeat', 'Search', 'SignColumn', 'Special', 'SpecialChar', 'SpecialComment', 'SpellBad', 'Statement', 'StorageClass', 'String', 'Structure', 'Tag', 'Title', 'Todo', 'Type', 'Typedef', 'Underlined', 'VertSplit', 'WarningMsg' ]
    exe 'hi ' . i . ' NONE'
  endfor

  hi Comment gui=italic guifg=#${black_fg}
  hi Cursor guibg=#${red_fg}
  hi Cursor2 guibg=#${green_fg}
  hi Delimiter gui=bold
  hi EndOfBuffer guifg=#${background}
  hi Folded guibg=#${white_bg} guifg=#${white_fg}
  hi IncSearch gui=bold guibg=#${yellow_fg} guifg=#${black_fg}
  hi Keyword gui=italic
  hi LineNr guibg=#${white_bg} guifg=#${black_bg}
  hi MatchParen gui=bold guifg=#${red_fg}
  hi NonText ctermfg=red guifg=red cterm=bold gui=bold
  hi NonText guifg=#${foreground}
  hi Normal guifg=#${foreground} guibg=NONE
  hi Search gui=bold,underline guifg=#${yellow_fg}
  hi SpellBad NONE cterm=undercurl gui=undercurl guifg=#${red_fg}
  hi StatusLine gui=NONE guibg=#222222 guifg=#ffffff
  hi StatusLineNC gui=NONE guibg=#${black_fg} guifg=#${foreground}
  hi VertSplit guifg=#${white_bg}
  hi Visual guibg=#${white_bg}
''
