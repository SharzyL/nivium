#!/usr/bin/env bash

RECIPIENT="me@sharzy.in"
KEYDIR=$HOME/.config/totp

_help() {
    echo "TOTP manager based on https://github.com/jakwings/bash-totp/"    
    echo "USAGE: totpctl [a|add|g|gen] <service>"
    exit 1
}

_init() {
    which totp >/dev/null || die "No totp installed"
    [ -d "$KEYDIR" ] || mkdir "$KEYDIR"
}

die() {
    echo "Error: $1" >&2
    exit 1
}

totp_add() {
    local org=$1
    [ -n "$org" ] || die "No org specified"

    local secrete
    [ -n "$secrete" ] || read -rp "Input the key: " secrete
    secrete=$(echo "$secrete" | tr '[:lower:]' '[:upper:]')

    echo "$secrete" | gpg --recipient "$RECIPIENT" --output "$KEYDIR/$org" -e
}

totp_gen() {
    local org=$1
    local keyfile="$KEYDIR/$org"
    [ -f "$keyfile" ] || die "Cannot find $keyfile"
    local secrete
    secrete="$(gpg -d "$KEYDIR/$org" 2>/dev/null)"
    local key
    key=$(totp "$secrete")
    echo "TOTP: $key"
    if which xclip >/dev/null; then 
        echo "$key" | xclip -selection clipboard
        echo "TOTP is moved to clipboard"
    fi
}

totp_list() {
    ls "$KEYDIR" -1
}

main() {
    _init
    case "$1" in
        "")
            _help
            ;;
        a|add)
            command=add
            ;;
        g|gen)
            command=gen
            ;;
        l|list)
            command=list
            ;;
    esac
    shift
    "totp_$command" "$@"
}

main "$@"

