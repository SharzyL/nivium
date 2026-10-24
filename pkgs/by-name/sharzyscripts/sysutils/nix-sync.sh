#!/usr/bin/env bash

registry="$HOME/.config/nix/registry.json"

get_rev() {
  jq -r --arg id "$1" '.flakes | map(select(.from.id == $id)) | .[0].to.rev' "$registry"
}

# print the immutable tarball url of the channel whose head is at the given rev, if any
channel_url() {
  local ch url
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
  nixpkgs_url=$(channel_url "$nixpkgs_rev")
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
