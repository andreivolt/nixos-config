{
  home-manager.sharedModules = [
    {
      xdg.configFile."rubocop/config.yml".text = ''
        Layout/AccessModifierIndentation: {EnforcedStyle: outdent}
        Layout/ArgumentAlignment: {EnforcedStyle: with_fixed_indentation}
        Layout/CommentIndentation: {enabled: false}
        Layout/FirstArgumentIndentation: {EnforcedStyle: consistent}
        Lint/Debugger: {enabled: false}
        Lint/ElseLayout: {enabled: false}
        Metrics/LineLength: {enabled: false}
        Metrics/MethodLength: {enabled: false}
        Style/CommentAnnotation: {enabled: false}
        Style/FrozenStringLiteralComment: {enabled: false}
        Style/MultilineBlockChain: {enabled: false}
        Style/NumericLiterals: {enabled: false}
        Style/StringLiterals: {enabled: false}
      '';
    }
  ];
}
