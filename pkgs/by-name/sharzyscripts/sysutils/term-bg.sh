#!/usr/bin/env bash

# Report whether the terminal has a light or a dark background, by asking it with
# an OSC 11 query. The terminal emulator itself answers, so unlike $COLORFGBG or
# a per-host setting this also works over ssh: it tells us the color of the
# window we are actually being drawn in.

set -euo pipefail

readonly DEFAULT_TIMEOUT=0.5

# a background counts as light above this relative luminance (WCAG)
readonly LIGHT_THRESHOLD=0.5

# the OSC 11 query. Inside tmux it has to be wrapped in a passthrough sequence
# (with every ESC doubled) to reach the outer terminal, which in turn needs
# "set -g allow-passthrough on".
readonly QUERY=$'\e]11;?\e\\'
# some terminals only recognise the older BEL-terminated form
readonly QUERY_BEL=$'\e]11;?\a'
readonly QUERY_TMUX=$'\ePtmux;\e\e]11;?\e\e\\\e\\'

usage() {
  cat <<EOF
Usage: term-bg [OPTION]...

Ask the terminal for its background color (OSC 11) and report whether it is
light or dark. Works over ssh, since the reply comes from the terminal emulator.

Options:
  -c, --color        print the background color as #rrggbb instead of light/dark
  -l, --is-light     print nothing, report the answer in the exit status only
  -t, --timeout SEC  how long to wait for the reply (default $DEFAULT_TIMEOUT)
  -h, --help         show this help

Exit status:
  0  detected (with --is-light: the background is light)
  1  with --is-light: the background is dark
  2  no answer: not running on a terminal, the terminal does not support OSC 11,
     or its reply could not be parsed

Environment:
  TERM_THEME_OVERRIDE  set to "light" or "dark" to answer without querying the
                       terminal, for one that stays silent (ignored by --color)

A background counts as light when its relative luminance exceeds $LIGHT_THRESHOLD.
EOF
}

die() {
  echo "term-bg: $*" >&2
  exit 2
}

# Send an OSC 11 query to /dev/tty and echo back whatever the terminal replies
# within the timeout. Nothing else is written to stdout, so that callers can use
# this in a command substitution.
ask_terminal() {
  local query=$1 timeout=$2 reply='' saved='' deci

  # the brace group keeps fd 3 open in this shell while swallowing bash's own
  # complaint when there is no controlling terminal to open
  { exec 3<>/dev/tty; } 2>/dev/null || return 1

  # "stty time" counts deciseconds, and has to cover the wait for the first byte:
  # a shorter value reports EOF before a slow link has delivered anything
  deci=$(awk -v t="$timeout" 'BEGIN { d = int(t * 10 + 0.5); print (d < 1) ? 1 : d }')

  saved=$(stty -g <&3)
  restore() {
    stty "$saved" <&3 2>/dev/null || true
  }
  trap restore EXIT INT TERM

  stty raw -echo min 0 time "$deci" <&3
  printf '%s' "$query" >&3

  # The reply has no newline, and ends with either BEL or ST. Stopping at that
  # terminator keeps a successful query down to one round trip, instead of always
  # waiting out the timeout; only the first byte has to wait for the terminal.
  local ch count=0
  if IFS= read -r -N 1 -t "$timeout" ch <&3; then
    reply=$ch
    # the rest of the reply is already buffered, so stop waiting on the link
    stty min 0 time 1 <&3
    while [ "$count" -lt 64 ]; do
      case $reply in
        *$'\a' | *$'\e\\') break ;;
      esac
      IFS= read -r -N 1 -t 0.2 ch <&3 || break
      reply+=$ch
      count=$(( count + 1 ))
    done
  fi

  restore
  trap - EXIT INT TERM
  exec 3>&-

  printf '%s' "$reply"
}

# Turn a 1-to-4 hex digit color component into 0..255
scale_component() {
  local hex=$1 max
  max=$(( 16 ** ${#hex} - 1 ))
  echo $(( (16#$hex * 255 + max / 2) / max ))
}

# Parse "rgb:rrrr/gggg/bbbb", "rgba:rrrr/gggg/bbbb/aaaa" or "#rrggbb" out of a
# reply, into three 0..255 components
parse_reply() {
  local reply=$1
  if [[ $reply =~ rgba?:([0-9a-fA-F]{1,4})/([0-9a-fA-F]{1,4})/([0-9a-fA-F]{1,4}) ]]; then
    echo "$(scale_component "${BASH_REMATCH[1]}")" \
      "$(scale_component "${BASH_REMATCH[2]}")" \
      "$(scale_component "${BASH_REMATCH[3]}")"
  elif [[ $reply =~ \#([0-9a-fA-F]{2})([0-9a-fA-F]{2})([0-9a-fA-F]{2}) ]]; then
    echo "$(( 16#${BASH_REMATCH[1]} ))" \
      "$(( 16#${BASH_REMATCH[2]} ))" \
      "$(( 16#${BASH_REMATCH[3]} ))"
  else
    return 1
  fi
}

is_light() {
  awk -v r="$1" -v g="$2" -v b="$3" -v threshold="$LIGHT_THRESHOLD" '
    function linear(v) {
      v = v / 255
      return (v <= 0.04045) ? v / 12.92 : ((v + 0.055) / 1.055) ^ 2.4
    }
    BEGIN {
      y = 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b)
      exit (y > threshold) ? 0 : 1
    }
  '
}

main() {
  local mode=report timeout=$DEFAULT_TIMEOUT

  while [ $# -gt 0 ]; do
    case $1 in
      -c | --color) mode=color ;;
      -l | --is-light) mode=is-light ;;
      -t | --timeout)
        [ $# -ge 2 ] || die "$1 needs an argument"
        timeout=$2
        shift
        ;;
      -h | --help)
        usage
        exit 0
        ;;
      *)
        usage >&2
        die "unknown argument: $1"
        ;;
    esac
    shift
  done

  local answer=''
  if [ "$mode" != color ]; then
    case ${TERM_THEME_OVERRIDE:-} in
      light | dark) answer=$TERM_THEME_OVERRIDE ;;
      '') ;;
      *)
        die "TERM_THEME_OVERRIDE must be \"light\" or \"dark\", got" \
          "\"$TERM_THEME_OVERRIDE\""
        ;;
    esac
  fi

  local r g b
  if [ -z "$answer" ]; then
    # Try the ST-terminated query first, then the BEL-terminated one. Only a
    # terminal that stayed silent gets asked again, so a working terminal still
    # costs a single round trip.
    local -a attempts=("$QUERY" "$QUERY_BEL")
    # tmux only forwards the query with allow-passthrough on; if it does not, an
    # unwrapped query still reaches tmux itself, which knows its own background
    [ -n "${TMUX:-}" ] && attempts=("$QUERY_TMUX" "$QUERY" "$QUERY_BEL")
    local reply=''
    local query
    for query in "${attempts[@]}"; do
      reply=$(ask_terminal "$query" "$timeout") || die "cannot open /dev/tty"
      [ -n "$reply" ] && break
    done
    # A console layer (Windows ConPTY) or a multiplexer in between answers the
    # simple queries itself but cannot report a color it does not own, which
    # looks exactly like a terminal without OSC 11: hence the override.
    [ -n "$reply" ] ||
      die "the terminal did not answer the OSC 11 query;" \
        "set TERM_THEME_OVERRIDE for a terminal that cannot"
    # assign first: a command substitution inside <<< would hide the exit status
    local rgb
    rgb=$(parse_reply "$reply") ||
      die "cannot parse the terminal's reply"
    read -r r g b <<<"$rgb"
    if is_light "$r" "$g" "$b"; then answer=light; else answer=dark; fi
  fi

  case $mode in
    color) printf '#%02x%02x%02x\n' "$r" "$g" "$b" ;;
    is-light) [ "$answer" = light ] ;;
    report) echo "$answer" ;;
  esac
}

main "$@"
