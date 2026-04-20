# -b/--build-dir option (complete with directories)
complete -c crun -s b -l build-dir -d "Build directory" -r -a "(__fish_complete_directories)"

# Function to get build targets using CMake File API
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

    if not test -d $build_dir
        return
    end

    # Try CMake File API
    set -l api_dir $build_dir/.cmake/api/v1
    set -l query_dir $api_dir/query
    set -l reply_dir $api_dir/reply

    mkdir -p $query_dir 2>/dev/null
    touch $query_dir/codemodel-v2 2>/dev/null

    set -l index_file (find $reply_dir -name 'index-*.json' -type f 2>/dev/null | sort -r | head -1)

    if test -n "$index_file"
        set -l codemodel_ref (jq -r '.reply."codemodel-v2".jsonFile' $index_file 2>/dev/null)
        if test -n "$codemodel_ref"
            set -l codemodel_file $reply_dir/$codemodel_ref
            for target_file in (jq -r '.configurations[0].targets[].jsonFile' $codemodel_file 2>/dev/null)
                jq -r 'select(.type == "EXECUTABLE" or .type == "STATIC_LIBRARY" or .type == "SHARED_LIBRARY") | .name' $reply_dir/$target_file 2>/dev/null
            end
            and return
        end
    end

    # Fallback to ninja
    ninja -C $build_dir -t targets 2>/dev/null | string replace -r ':.*$' "" | string trim
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
