{
  writeShellScriptBin,
  git,
  coreutils,
}:
writeShellScriptBin "git-edit-commits" ''
  set -euo pipefail

  usage() {
    echo "Usage: git-edit-commits [<revision-range>]"
    echo ""
    echo "Edit commit messages in \$EDITOR, edir-style."
    echo ""
    echo "Examples:"
    echo "  git-edit-commits HEAD~5    # Edit last 5 commits"
    echo "  git-edit-commits main..    # Edit commits since main"
    echo "  git-edit-commits           # Defaults to HEAD~10"
    exit 1
  }

  if [[ "''${1:-}" == "-h" || "''${1:-}" == "--help" ]]; then
    usage
  fi

  range="''${1:-HEAD~10..HEAD}"

  if [[ "$range" =~ ^HEAD~[0-9]+$ ]]; then
    range="$range..HEAD"
  fi

  commits=$(${git}/bin/git log --format="%h %s" "$range" 2>/dev/null) || {
    echo "Error: Invalid revision range '$range'" >&2
    exit 1
  }

  if [[ -z "$commits" ]]; then
    echo "No commits in range '$range'" >&2
    exit 1
  fi

  tmpdir=$(${coreutils}/bin/mktemp -d)
  trap '${coreutils}/bin/rm -rf "$tmpdir"' EXIT

  original="$tmpdir/original"
  edited="$tmpdir/edited"

  echo "$commits" > "$original"
  ${coreutils}/bin/cp "$original" "$edited"

  ''${EDITOR:-vi} "$edited"

  if ${coreutils}/bin/diff -q "$original" "$edited" >/dev/null 2>&1; then
    echo "No changes made."
    exit 0
  fi

  mapfile -t orig_lines < "$original"
  mapfile -t edit_lines < "$edited"

  if [[ ''${#orig_lines[@]} -ne ''${#edit_lines[@]} ]]; then
    echo "Error: Number of commits changed. Don't add or remove lines." >&2
    exit 1
  fi

  declare -A changes
  oldest_changed_idx=-1

  for i in "''${!orig_lines[@]}"; do
    orig_hash=$(echo "''${orig_lines[$i]}" | ${coreutils}/bin/cut -d' ' -f1)
    orig_msg=$(echo "''${orig_lines[$i]}" | ${coreutils}/bin/cut -d' ' -f2-)

    edit_hash=$(echo "''${edit_lines[$i]}" | ${coreutils}/bin/cut -d' ' -f1)
    edit_msg=$(echo "''${edit_lines[$i]}" | ${coreutils}/bin/cut -d' ' -f2-)

    if [[ "$orig_hash" != "$edit_hash" ]]; then
      echo "Error: Commit hash changed on line $((i+1)). Don't modify hashes." >&2
      exit 1
    fi

    if [[ "$orig_msg" != "$edit_msg" ]]; then
      changes["$orig_hash"]="$edit_msg"
      if [[ $oldest_changed_idx -eq -1 ]]; then
        oldest_changed_idx=$i
      fi
    fi
  done

  if [[ $oldest_changed_idx -eq -1 ]]; then
    echo "No changes detected."
    exit 0
  fi

  oldest_hash=""
  for i in "''${!orig_lines[@]}"; do
    hash=$(echo "''${orig_lines[$i]}" | ${coreutils}/bin/cut -d' ' -f1)
    if [[ -n "''${changes[$hash]:-}" ]]; then
      oldest_hash="$hash"
    fi
  done

  echo "Updating ''${#changes[@]} commit(s)..."

  msgdir="$tmpdir/messages"
  ${coreutils}/bin/mkdir -p "$msgdir"
  for hash in "''${!changes[@]}"; do
    printf '%s' "''${changes[$hash]}" > "$msgdir/$hash"
  done

  seq_editor="$tmpdir/seq-editor.sh"
  cat > "$seq_editor" << SEQEOF
#!/usr/bin/env bash
set -e
file="\$1"
tmpfile="\$(mktemp)"
msgdir="$msgdir"

while IFS= read -r line; do
  echo "\$line" >> "\$tmpfile"
  if [[ "\$line" =~ ^pick[[:space:]]+([a-f0-9]+) ]]; then
    short="\''${BASH_REMATCH[1]}"
    for msgfile in "\$msgdir"/*; do
      stored_hash=\$(basename "\$msgfile")
      if [[ "\$short" == "\$stored_hash"* ]] || [[ "\$stored_hash" == "\$short"* ]]; then
        echo "exec git commit --amend --file=\$msgfile" >> "\$tmpfile"
        break
      fi
    done
  fi
done < "\$file"

mv "\$tmpfile" "\$file"
SEQEOF
  ${coreutils}/bin/chmod +x "$seq_editor"

  parent=$(${git}/bin/git rev-parse "$oldest_hash^")
  GIT_SEQUENCE_EDITOR="$seq_editor" ${git}/bin/git rebase -i --committer-date-is-author-date "$parent"

  echo "Done!"
''
