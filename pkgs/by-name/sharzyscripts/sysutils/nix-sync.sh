#!/usr/bin/env bash

registry="$HOME/.config/nix/registry.json"

get_rev() {
  jq -r --arg id "$1" '.flakes | map(select(.from.id == $id)) | .[0].to.rev' "$registry"
}

nixpkgs_rev=$(get_rev nixpkgs)
flake_parts_rev=$(get_rev flake-parts)
treefmt_nix_rev=$(get_rev treefmt-nix)

args=(nix flake update --no-warn-dirty nixpkgs flake-parts treefmt-nix)

if [ -n "$nixpkgs_rev" ] && [ "$nixpkgs_rev" != "null" ]; then
  args+=(--override-flake nixpkgs "github:NixOS/nixpkgs/$nixpkgs_rev")
fi

if [ -n "$flake_parts_rev" ] && [ "$flake_parts_rev" != "null" ]; then
  args+=(--override-flake flake-parts "github:hercules-ci/flake-parts/$flake_parts_rev")
fi

if [ -n "$treefmt_nix_rev" ] && [ "$treefmt_nix_rev" != "null" ]; then
  args+=(--override-flake treefmt-nix "github:numtide/treefmt-nix/$treefmt_nix_rev")
fi

echo "${args[*]}"
"${args[@]}"
