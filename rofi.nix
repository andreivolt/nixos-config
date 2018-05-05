{ pkgs, ... }:

let
  myFonts = {
    proportional = "Abel";
    monospace = "Source Code Pro";
  };

in {
  environment.systemPackages = with pkgs; [ rofi ];

  home-manager.users.avo
    .xresources.properties = let fontSize = "28"; in {
      "rofi.font"  = "${myFonts.proportional} ${fontSize}";
      "rofi.theme" = "avo";
    };

  home-manager.users.avo
    .home.file.".local/share/rofi/themes/avo.rasi".text = let theme = import ./themes/challenger-deep.nix; in ''
      * {
          text-color:                  ${theme.foreground};
          background-color:            ${theme.black};
          lightbg:                     ${theme.background};
          red:                         ${theme.red};
          orange:                      ${theme.yellow};
          blue:                        ${theme.cyan};

          active-background:           @orange;
          active-foreground:           @foreground;
          alternate-active-background: @blue;
          alternate-active-foreground: @foreground;
          alternate-normal-background: @background;
          alternate-normal-foreground: @foreground;
          alternate-urgent-background: @background;
          alternate-urgent-foreground: @foreground;
          bordercolor:                 @foreground;
          normal-background:           @background;
          normal-foreground:           @foreground;
          selected-active-background:  @blue;
          selected-active-foreground:  @foreground;
          selected-normal-background:  @blue;
          selected-normal-foreground:  ${theme.black};
          selected-urgent-background:  @red;
          selected-urgent-foreground:  @foreground;
          separatorcolor:              @orange;
          spacing:                     5;
          urgent-background:           @red;
          urgent-foreground:           @foreground;
      }

      #window {
          border:           0;
          text-color:       @foreground;
          padding:          20;
          background-color: @background;
      }

      #mainbox {
          border:  0;
          padding: 0;
      }

      #message {
          border:     1px dash 0px 0px;
          text-color: @separatorcolor;
          padding:    2px 0px 0px;
      }

      #textbox {
          text-color: @foreground;
      }

      #listview {
          fixed-height: 0;
          border:       2px 0px 0px;
          padding:      2px 0px 0px;
          text-color:   @separatorcolor;
      }
      #element {
          border:  0;
          padding: 2px 8px;
      }

      #element.normal.normal {
          text-color:       @normal-foreground;
          background-color: @normal-background;
      }

      #element.normal.urgent {
          text-color:       @urgent-foreground;
          background-color: @urgent-background;
      }

      #element.normal.active {
          text-color:       @active-foreground;
          background-color: @active-background;
      }

      #element.selected.normal {
          text-color:       @selected-normal-foreground;
          background-color: @selected-normal-background;
      }

      #element.selected.urgent {
          text-color:       @selected-urgent-foreground;
          background-color: @selected-urgent-background;
      }

      #element.selected.active {
          text-color:       @selected-active-foreground;
          background-color: @selected-active-background;
      }

      #element.alternate.normal {
          text-color:       @alternate-normal-foreground;
          background-color: @alternate-normal-background;
      }

      #element.alternate.urgent {
          text-color:       @alternate-urgent-foreground;
          background-color: @alternate-urgent-background;
      }

      #element.alternate.active {
          text-color:       @alternate-active-foreground;
          background-color: @alternate-active-background;
      }

      #sidebar {
          border: 1px dash 0px 0px;
      }

      #button selected {
          text-color:       @selected-normal-foreground;
          background-color: @selected-normal-background;
      }

      #inputbar {
          spacing: 0;
          border:  0;
          margin:  0 0 10px 0;
      }

      #button normal {
          text-color: @foreground;
      }

      #inputbar {
          children:   [ prompt, textbox-prompt-colon, entry, case-indicator ];
      }

      #textbox-prompt-colon {
          expand:     false;
          str:        ":";
          margin:     0px 0.3em 0em 0em;
          text-color: @normal-foreground;
      }
    '';
}
