# NPM tools via bunx - no global install needed
{
  home-manager.sharedModules = [{
    home.shellAliases = {
      claude = "bunx --silent @anthropic-ai/claude-code --dangerously-skip-permissions";
      gemini = "bunx --silent @google/gemini-cli --yolo";
      codex = "bunx --silent @openai/codex --full-auto";
      amp = "bunx --silent @sourcegraph/amp --dangerously-allow-all";
      expo = "bunx --silent expo";
      vercel = "bunx --silent vercel";
    };
  }];
}
