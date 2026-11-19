#!/usr/bin/env bash

registry="$HOME/.config/nix/registry.json"
lock=

usage() {
  echo "usage: nix-sync [-l|--lock <flake.lock or flake dir>]"
  echo "pin nixpkgs, flake-parts and treefmt-nix of ./flake.lock to the revs in the user registry, or in the given lock file"
}

while [ $# -gt 0 ]; do
  case "$1" in
    -l | --lock)
      lock="${2:?--lock needs a path}"
      shift 2
      ;;
    -h | --help)
      usage
      exit
      ;;
    *)
      usage >&2
      exit 1
      ;;
  esac
done

if [ -d "$lock" ]; then
  lock="$lock/flake.lock"
fi

# the locked ref of the given flake id: the root input of that name in the lock
# file if given (nothing if it follows another input), otherwise the registry entry
get_locked() {
  if [ -n "$lock" ]; then
    jq -c --arg id "$1" '.nodes[.nodes.root.inputs[$id] | strings].locked' "$lock"
  else
    jq -c --arg id "$1" '.flakes | map(select(.from.id == $id)) | .[0].to' "$registry"
  fi
}

get_rev() {
  get_locked "$1" | jq -r .rev
}

get_path() {
  get_locked "$1" | jq -r .path
}

# a locked tarball is already an immutable release url
get_url() {
  get_locked "$1" | jq -r 'select(.type == "tarball") | .url'
}

# print the tarball url of the channel release at the given rev, if any
channel_url() {
  local ch url ver
  # channel tarballs ship the release version, which names the release directory
  # e.g. https://releases.nixos.org/nixos/unstable-small/nixos-26.11pre1098928.dce1caf58d1a/nixexprs.tar.xz
  if [ -f "$2/.version-suffix" ] && [ "$(cat "$2/.git-revision" 2>/dev/null)" = "$1" ]; then
    ver="$(cat "$2/lib/.version")$(cat "$2/.version-suffix")"
    for ch in nixos/unstable-small/nixos nixos/unstable/nixos nixpkgs/nixpkgs; do
      url="https://releases.nixos.org/$ch-$ver/nixexprs.tar.xz"
      if curl -fsI -o /dev/null --max-time 5 "$url"; then
        echo "$url"
        return
      fi
    done
  fi

  # otherwise, check whether the given rev is the head of some channel
  for ch in nixos-unstable-small nixos-unstable nixpkgs-unstable; do
    # the channel redirects with a `Link: <url?rev=...&lastModified=...>; rel="immutable"` header
    url=$(curl -fsSI --max-time 5 "https://channels.nixos.org/$ch/nixexprs.tar.xz" |
      sed -nE 's/^link: <([^>]*)>; rel="immutable".*/\1/Ip' | tr -d '\r') || continue
    if [[ "$url" == *"rev=$1&"* ]]; then
      echo "$url"
      return
    fi
  done
}

nixpkgs_rev=$(get_rev nixpkgs)
flake_parts_rev=$(get_rev flake-parts)
treefmt_nix_rev=$(get_rev treefmt-nix)

args=(nix flake update --no-warn-dirty nixpkgs flake-parts treefmt-nix)

if [ -n "$nixpkgs_rev" ] && [ "$nixpkgs_rev" != "null" ]; then
  nixpkgs_url=$(get_url nixpkgs)
  if [ -z "$nixpkgs_url" ]; then
    nixpkgs_url=$(channel_url "$nixpkgs_rev" "$(get_path nixpkgs)")
  fi
  args+=(--override-flake nixpkgs "${nixpkgs_url:-github:NixOS/nixpkgs/$nixpkgs_rev}")
fi

if [ -n "$flake_parts_rev" ] && [ "$flake_parts_rev" != "null" ]; then
  args+=(--override-flake flake-parts "github:hercules-ci/flake-parts/$flake_parts_rev")
fi

if [ -n "$treefmt_nix_rev" ] && [ "$treefmt_nix_rev" != "null" ]; then
  args+=(--override-flake treefmt-nix "github:numtide/treefmt-nix/$treefmt_nix_rev")
fi

echo "${args[*]}"
"${args[@]}"
