{ pkgs, ... }:

{
  home-manager.users.avo.home.packages = with pkgs; [
    (weechat.override {
      configure = { availablePlugins, ... }: {
        init = ''
          /set foo bar
          /server add freenode chat.freenode.org
        '';
        scripts = with weechatScripts; [
          multiline
          # wee-slack
          weechat-matrix
          weechat-notify-send
        ];
        plugins = [
          (availablePlugins.python.withPackages (_: [ weechatScripts.weechat-matrix ]))
        ];
      };
    })
  ];
}
