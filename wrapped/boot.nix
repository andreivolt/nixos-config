self: super: with super; {

boot = let _ = ''
  wrapProgram $out/bin/boot \
    --set-default BOOT_VERSION 2.8.2 \
    --set-default BOOT_CLOJURE_VERSION 1.8.0 \
    --set-default BOOT_JVM_OPTIONS '\
            -client \
            -Xmx2g \
            -Xverify:none \
            -XX:+CMSClassUnloadingEnabled \
            -XX:+TieredCompilation \
            -XX:+UseConcMarkSweepGC \
            -XX:TieredStopAtLevel=1' '';
in hiPrio (stdenv.lib.overrideDerivation boot (attrs: {
  buildInputs = attrs.buildInputs or [] ++ [ makeWrapper ];
  postInstall = attrs.postInstall or "" + _; }));

}
