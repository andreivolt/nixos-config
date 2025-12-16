# Python tools via uvx - no global install needed
{
  home-manager.sharedModules = [{
    home.shellAliases = {
      jtbl = "uvx --quiet jtbl";
      llm = "uvx --quiet --with llm-anthropic,llm-cmd,llm-gemini,llm-grok,llm-openrouter llm";
      streamdown = "uvx --quiet streamdown";
      strip-tags = "uvx --quiet strip-tags";
      ttok = "uvx --quiet ttok";
      whisperx = "uvx --quiet whisperx";
    };
  }];
}
