#!/usr/bin/env bash

build_dir="build"

while getopts "b:" opt; do
    case $opt in
        b) build_dir="$OPTARG" ;;
        *) echo "Usage: crun [-b BUILD_DIR] TARGET [ARGS...]" >&2
           echo "Example: crun oram_test -l 20 -t TGPU" >&2
           exit 1 ;;
    esac
done
shift $((OPTIND - 1))

if [ $# -lt 1 ]; then
    echo "Usage: crun [-b BUILD_DIR] TARGET [ARGS...]" >&2
    echo "Example: crun oram_test -l 20 -t TGPU" >&2
    exit 1
fi

target="$1"
shift

build_start=$(date +%s.%N)
ninja -C "$build_dir" "$target" || exit $?
build_end=$(date +%s.%N)
build_secs=$(echo "$build_end - $build_start" | bc)
build_ms=$(echo "$build_secs * 1000" | bc | cut -d. -f1)

dim=$'\e[90m'
reset=$'\e[0m'
if [ "${build_ms:-0}" -ge 1000 ]; then
    printf "%sBuild time: %.2fs%s\n" "$dim" "$build_secs" "$reset"
else
    printf "%sBuild time: %dms%s\n" "$dim" "$build_ms" "$reset"
fi

# Resolve phony targets to real executable path
exe_path=$(ninja -C "$build_dir" -t query "$target" 2>/dev/null | grep -A 1 "input: phony" | tail -n 1 | sed 's/^[[:space:]]*//')

if [ -z "$exe_path" ]; then
    exe_path="$target"
fi

exec "$build_dir/$exe_path" "$@"
