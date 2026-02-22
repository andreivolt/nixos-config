{pkgs, ...}:
let
  colors = import ../colors.nix;
  aurora = colors.aurora;
  foot = pkgs.andrei.foot-custom;

  stripHash = s: builtins.replaceStrings ["#"] [""] s;

  footColors = ''
    [colors-dark]
    alpha=1.0
    foreground=${stripHash aurora.foreground}
    background=${stripHash aurora.background}

    selection-foreground=${stripHash aurora.selection.foreground}
    selection-background=${stripHash aurora.selection.background}

    urls=${stripHash aurora.normal.cyan}

    cursor=${stripHash aurora.cursorText} ${stripHash aurora.cursor}

    regular0=${stripHash aurora.normal.black}
    regular1=${stripHash aurora.normal.red}
    regular2=${stripHash aurora.normal.green}
    regular3=${stripHash aurora.normal.yellow}
    regular4=${stripHash aurora.normal.blue}
    regular5=${stripHash aurora.normal.magenta}
    regular6=${stripHash aurora.normal.cyan}
    regular7=${stripHash aurora.normal.white}

    bright0=${stripHash aurora.bright.black}
    bright1=${stripHash aurora.bright.red}
    bright2=${stripHash aurora.bright.green}
    bright3=${stripHash aurora.bright.yellow}
    bright4=${stripHash aurora.bright.blue}
    bright5=${stripHash aurora.bright.magenta}
    bright6=${stripHash aurora.bright.cyan}
    bright7=${stripHash aurora.bright.white}

    16=${stripHash aurora.extended.color16}
    17=${stripHash aurora.extended.color17}
  '';
in {
  home-manager.sharedModules = [
    ({...}: {
      home.packages = [ foot ];

      xdg.configFile."foot/foot.ini".text = ''
        [main]
        font=Pragmasevka Nerd Font Light:size=13
        font-bold=Pragmasevka Nerd Font SemiBold:size=13
        font-italic=Pragmasevka Nerd Font Light:size=13:style=italic
        font-bold-italic=Pragmasevka Nerd Font SemiBold:size=13:style=italic
        letter-spacing=-1
        pad=5x5
        selection-target=clipboard
        scrollback-pager=nvim-pager

        [cursor]
        style=beam
        blink=yes
        beam-thickness=1

        [bell]
        urgent=no
        notify=no
        visual=no

        [scrollback]
        lines=10000

        [url]
        launch=xdg-open ''${url}

        ${footColors}

        [key-bindings]
        scrollback-pager=Control+Shift+h
        font-increase=Control+plus Control+equal Control+KP_Add
        font-decrease=Control+minus Control+KP_Subtract
        font-reset=Control+0 Control+Shift+BackSpace


        [tweak]
        grapheme-shaping=yes
        overflowing-glyphs=yes
        text-thickness-compensation=0.25
        surface-bit-depth=8-bit
      '';

      systemd.user.services.foot-server = {
        Unit = {
          Description = "Foot terminal server mode";
          Documentation = "man:foot(1)";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = "${foot}/bin/foot --server";
          Restart = "on-failure";
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };
    })
  ];
}
