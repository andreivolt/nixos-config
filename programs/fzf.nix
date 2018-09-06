{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ fzf ];

  environment.variables.FZF_DEFAULT_OPTS = ''
    --color fg:250,fg+:12,bg:16,bg+:16,hl:3,hl+:3,pointer:12,info:15,prompt:7 \
    --no-bold
  '';
}
