#!/usr/bin/env bash

SC_DIR="${1:-$HOME/tmp/_screenshots}"
echo "monitoring '$SC_DIR'"
[ -d "$SC_DIR" ] || echo "directory '$SC_DIR' not existing" || exit 1

while true; do
  f="$(inotifywait -q "$SC_DIR" --event close_write --format "%w%f")"
  case ${f##*.} in
    jpg|JPG)
      mime=image/jpg
      ;;
    png|PNG)
      mime=image/png
      ;;
    *)
      echo "unknown file extension of file '$f'" >&2
      continue
  esac

  echo "new screenshot '$f' of mime '$mime'" >&2

  if [ -v WAYLAND_DISPLAY ]; then
    wl-copy -t "$mime" < "$f"
  else
    xclip -se c -t "$mime" -i "$f"
  fi
done

