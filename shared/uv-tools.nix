# Python tools via uvx - no global install needed
{
  home-manager.sharedModules = [{
    home.shellAliases = {
      jtbl = "uvx jtbl";
      llm = "uvx --with llm-anthropic,llm-cmd,llm-gemini,llm-grok,llm-openrouter llm";
      streamdown = "uvx streamdown";
      strip-tags = "uvx strip-tags";
      ttok = "uvx ttok";
      whisperx = "uvx whisperx";
    };
  }];
}
