set -o pipefail

main() {
  for f in "$@"; do
    if [ -v NO_ICONV ]; then
      converted=$(perl -pe 's/(?<=FILE ").*\\//g' "$f")
    else
      converted=$(iconv -f GB18030 "$f" | perl -pe 's/(?<=FILE ").*\\//g')
    fi
    bat -P -l asm <<< "$converted"
    echo -n "overwrite $f? (y/n)"
    read -r confirm
    if [ "$confirm" == 'y' ]; then
      cat > "$f" <<< "$converted"
    else
      echo "aborted"
    fi
  done
}

main "$@"

