# -b/--build-dir option (complete with directories)
complete -c crun -s b -l build-dir -d "Build directory" -r -a "(__fish_complete_directories)"

# Function to get ninja targets from the build directory
function __crun_get_targets
    set -l build_dir "build"

    set -l cmd (commandline -opc)
    for i in (seq (count $cmd))
        if test "$cmd[$i]" = "-b"; or test "$cmd[$i]" = "--build-dir"
            set -l next_idx (math $i + 1)
            if test $next_idx -le (count $cmd)
                set build_dir $cmd[$next_idx]
            end
            break
        end
    end

    if test -d $build_dir
        ninja -C $build_dir -t targets 2>/dev/null | string replace -r ':.*$' "" | string trim
    end
end

# Function to check if we've already specified a target
function __crun_needs_target
    set -l cmd (commandline -opc)
    set -l skip_next 0

    for i in (seq 2 (count $cmd))
        set -l arg $cmd[$i]

        if test $skip_next -eq 1
            set skip_next 0
            continue
        end

        if test "$arg" = "-b"; or test "$arg" = "--build-dir"
            set skip_next 1
            continue
        end

        if not string match -q -- '-*' $arg
            return 1
        end
    end

    return 0
end

# Complete target names (only when no target has been specified yet)
complete -c crun -f -n "__crun_needs_target" -a "(__crun_get_targets)" -d "Ninja target"
