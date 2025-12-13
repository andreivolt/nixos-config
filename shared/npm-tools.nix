# NPM tools via bunx - no global install needed
{
  home-manager.sharedModules = [{
    home.shellAliases = {
      claude = "bunx @anthropic-ai/claude-code";
      gemini = "bunx @google/gemini-cli";
      codex = "bunx @openai/codex";
      amp = "bunx @sourcegraph/amp";
      expo = "bunx expo";
      vercel = "bunx vercel";
    };
  }];
}
