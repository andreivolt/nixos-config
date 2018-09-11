self: super: with super; {

pdf2text = writeShellScriptBin "pdf2text" ''
  ${poppler_utils}/bin/pdftotext \
    "$@"'';

}
