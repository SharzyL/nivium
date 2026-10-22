#!/usr/bin/env bash
# $SSH_USER_AUTH is set by sshd with ExposeAuthInfo; skip nested shells (e.g. tmux)
if [ -z "${SSH_USER_AUTH:-}" ] || [ ! -r "$SSH_USER_AUTH" ] || [ -n "${TMUX:-}" ] || [ ! -t 1 ]; then
  exit 0
fi

bold=$'\e[1m'
red=$'\e[1;31m'
reset=$'\e[0m'
warn_secs=$((30 * 24 * 3600))

# sshd does not receive key comments, so look them up in authorized_keys
auth_files=()
for f in "/etc/ssh/authorized_keys.d/${USER:-$(id -un)}" "$HOME/.ssh/authorized_keys"; do
  if [ -r "$f" ]; then auth_files+=("$f"); fi
done
key_comment() {
  if [ "${#auth_files[@]}" -eq 0 ]; then return; fi
  awk -v key="$1" '
    /^[ \t]*#/ { next }
    {
      for (i = 1; i < NF; i++) if ($i == key) {
        c = $(i + 1); for (j = i + 2; j <= NF; j++) c = c " " $j
        print c; exit
      }
    }' "${auth_files[@]}"
}

echo "$bold""SSH authentication:$reset"
while read -r method type key _; do
  case "$type" in
    *-cert-v01@openssh.com)
      info=$(ssh-keygen -L -f /dev/stdin <<<"$type $key")
      field() { sed -n "s/^ *$1: //p" <<<"$info"; }
      valid=$(field Valid)
      echo "  $method: certificate $(field 'Key ID')"
      echo "    serial:  $(field Serial)"
      echo "    ca:      $(field 'Signing CA')"
      echo "    valid:   $valid"
      expiry=$(sed -n -e 's/.* to //p' -e 's/^before //p' <<<"$valid")
      if [ -n "$expiry" ]; then
        left=$(($(date -d "$expiry" +%s) - $(date +%s)))
        if [ "$left" -le 0 ]; then
          echo "    $red""certificate has expired$reset"
        elif [ "$left" -le "$warn_secs" ]; then
          echo "    $red""certificate expires in $((left / 86400)) days ($expiry)$reset"
        fi
      fi
      ;;
    "")
      echo "  $method"
      ;;
    *)
      echo "  $method: $(ssh-keygen -l -f /dev/stdin <<<"$type $key $(key_comment "$key")")"
      ;;
  esac
done <"$SSH_USER_AUTH"
