{
  home-manager.sharedModules = [
    {
      programs.readline = {
        enable = true;
        variables = {
          completion-ignore-case = true;
          show-all-if-ambiguous = true;
          blink-matching-paren = true;
          colored-stats = true;
          completion-display-width = 0;
          completion-map-case = true;
          menu-complete-display-prefix = true;
          editing-mode = "vi";
        };
        extraConfig = ''
          $if mode=vi
          set keymap vi-command

          Control-l: clear-screen
          ".": "i !*\r"
          "/": forward-search-history
          "?": reverse-search-history
          "C": "Da"
          "D": kill-line
          "G": end-of-history
          "gg": beginning-of-history
          "v": rlwrap-call-editor

          "ca'": "da'i"
          "ca(": "da(i"
          "ca)": "da(i"
          "ca/": "da/i"
          "ca:": "da:i"
          "ca<": "da<i"
          "ca>": "da>i"
          "ca[": "da[i"
          "ca\"": "da\"i"
          "ca]": "da]i"
          "ca`": "da`i"
          "caw": "lbcW"
          "ca{": "da{i"
          "ca}": "da}i"

          "cb": "dbi"
          "cc": "ddi"
          "cw": "dwi"

          "ci'": "di'i"
          "ci(": "di(i"
          "ci)": "di(i"
          "ci/": "di/i"
          "ci:": "di:i"
          "ci<": "di<i"
          "ci>": "di>i"
          "ci[": "di[i"
          "ci\"": "di\"i"
          "ci]": "di]i"
          "ci`": "di`i"
          "ciw": "lbcw"
          "ci{": "di{i"
          "ci}": "di}i"

          "da'": "lF'df'"
          "da(": "lF(df)"
          "da)": "lF(df)"
          "da/": "lF/df/"
          "da:": "lF:df:"
          "da<": "lF<df>"
          "da>": "lF<df>"
          "da[": "lF[df]"
          "da\"": "lF\"df\""
          "da]": "lF[df]"
          "da`": "lF\`df\`"
          "daw": "lbdW"
          "da{": "lF{df}"
          "da}": "lF{df}"

          "db": backward-kill-word
          "dd": kill-whole-line
          "dw": kill-word

          "di'": "lF'lmtf'd`t"
          "di(": "lF(lmtf)d`t"
          "di)": "lF(lmtf)d`t"
          "di/": "lF/lmtf/d`t"
          "di:": "lF:lmtf:d`t"
          "di<": "lF<lmtf>d`t"
          "di>": "lF<lmtf>d`t"
          "di[": "lF[lmtf]d`t"
          "di\"": "lF\"lmtf\"d`t"
          "di]": "lF[lmtf]d`t"
          "di`": "lF\`lmtf\`d`t"
          "diw": "lbdw"
          "di{": "lF{lmtf}d`t"
          "di}": "lF{lmtf}d`t"

          "yaw": "lbyW"
          "yiw": "lbyw"

          set keymap vi-insert
          Control-l: clear-screen
          TAB: menu-complete
          "\e[Z": menu-complete-backward
          $endif
        '';
      };
    }
  ];
}
