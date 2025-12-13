# NPM tools via bunx - no global install needed
{
  home-manager.sharedModules = [{
    home.shellAliases = {
      claude = "bunx @anthropic-ai/claude-code --dangerously-skip-permissions";
      gemini = "bunx @google/gemini-cli --yolo";
      codex = "bunx @openai/codex --full-auto";
      amp = "bunx @sourcegraph/amp --dangerously-allow-all";
      expo = "bunx expo";
      vercel = "bunx vercel";
    };
  }];
}
