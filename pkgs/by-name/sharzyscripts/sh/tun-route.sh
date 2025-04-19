#!/usr/bin/env bash

resolve() {
  getent hosts "$1" | awk '{print $1}'
}

resolve_to_route() {
  local name="$1"
  for ip in $(resolve "$name"); do
    echo "add route '$ip' ($name)"
    ip r add "$ip" dev socks
  done
}

tun2socks -proxy http://localhost:1094 -device socks &
sleep 0.2
ip l set socks up
resolve_to_route google.com
resolve_to_route proxy.golang.org
#resolve_to_route golang.org
resolve_to_route github.com
resolve_to_route raw.githubusercontent.com
resolve_to_route tarballs.nixos.org
resolve_to_route web.archive.org
resolve_to_route repo1.maven.org
resolve_to_route registry.npmjs.org
fg
