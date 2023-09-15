{
  home-manager.users.avo.programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      "add_newline" = true;
      # "aws" = {
      #   "format" = "[$symbol($profile)(\\[$duration\\])]($style)";
      #   "style" = "yellow";
      #   "symbol" = "☁️";
      # };
      "character" = {
        "error_symbol" = "[✗](bold red)";
        "format" = "$symbol ";
        "success_symbol" = "[➤](bold green)";
      };
      "cmd_duration" = {
        "disabled" = true;
      };
      "continuation_prompt" = "> ";
      "directory" = {
        "format" = "[$path]($style)[$read_only]($read_only_style) ";
        "style" = "blue";
        "truncate_to_repo" = false;
        "truncation_length" = 0;
      };
      "docker_context" = {
        "format" = "[$symbol$context]($style) ";
        "symbol" = "🐳";
      };
      "env_var" = {
        "NIX_SHELL_PACKAGES" = {
          "default" = "";
          "format" = "[( \\[$env_value\\])](purple)";
        };
      };
      "format" = "╭─ $all╰─ $character$jobs\n";
      "gcloud" = {
        "disabled" = true;
        "format" = "[ $symbol$account(@$domain)(\\($region\\))\\[$project\\]]($style)";
        "style" = "245";
      };
      "git_branch" = {
        "format" = "[\\[$branch(:$remote_branch)\\]]($style)";
        "style" = "#c1993b";
      };
      "git_status" = {
        "format" = "";
      };
      "hostname" = {
        "format" = "[$ssh_symbol$hostname]($style):";
        "style" = "purple";
      };
      "aws" = {
        "disabled" = true;
      };
      "java" = {
        "disabled" = true;
      };
      "kubernetes" = {
        "disabled" = false;
      };
      "nix_shell" = {
        "format" = "[$symbol$state(\\($name\\)) ]($style)";
        "style" = "purple";
      };
      "nodejs" = {
        "disabled" = true;
        "format" = "[ $symbol($version) ]($style) ";
        "symbol" = " ";
      };
      "package" = {
        "disabled" = true;
      };
      "perl" = {
        "disabled" = true;
      };
      "python" = {
        "disabled" = true;
      };
      "right_format" = "$ruby$docker_context$aws ";
      "ruby" = {
        "format" = "[$symbol($version) ]($style)";
        "style" = "red";
        "symbol" = "💎";
      };
      "username" = {
        "disabled" = true;
      };
    };
  };
}
