#!/usr/bin/env bash

runVerbose() {
  echo "$" "$@" >&2
  "$@"
}

tmpDir=$(mktemp -t -d nsw.XXXXXX)

cleanup() {
  rm -rf "$tmpDir"
}

run() {
  trap cleanup EXIT
  if [ -r flake.nix ]; then
    default_dir=.
  elif [ -v nixosConf ]; then
    default_dir="$nixosConf"
  elif [ -d /etc/nixos ]; then
    default_dir="$(readlink -f /etc/nixos)"
  else
    echo "cannot find nix flake dir"
    exit 1
  fi
  hostname="${hostname:-$(</etc/hostname)}"
  target="$default_dir#nixosConfigurations.$hostname.config.system.build.toplevel"
  if command -v iets >/dev/null && ! [ -v NSW_NO_IETS ]; then
    # iets evaluates faster, and its internal-json log records are what nom renders
    echo "$ iets build $target --out-link $tmpDir/result --log-format internal-json $* |& nom --json" >&2
    iets build "$target" --out-link "$tmpDir/result" --log-format internal-json "$@" 2>&1 >/dev/null | nom --json
  else
    runVerbose nom build "$target" --out-link "$tmpDir/result" --verbose "$@"
  fi
  outDir=$(readlink -f "$tmpDir/result")
  runVerbose sudo nix-env -p /nix/var/nix/profiles/system --set "$outDir"
  runVerbose sudo --preserve-env=NIXOS_INSTALL_BOOTLOADER -- "$outDir"/bin/switch-to-configuration switch
}

run "$@"
