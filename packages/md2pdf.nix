self: super: with super; {

md2pdf = writeShellScriptBin "md2pdf" ''
  eval set -- $(getopt -o s: --long font-size: -- $@)
  font_size=12
  while true; do
    case $1 in
      -s | --font-size) font_size=$2; shift ;;
      *) break ;;
    esac
  done

  out=$(mktemp).pdf
  ${pandoc}/bin/pandoc \
    -o $out \
    -V fontsize=''${font_size}pt &&
  cat $out'';

}
