#!/bin/bash

# 1 - a reference to a caller's remote packages array
# 2 - a reference to a caller's local packages array
# 3 - a reference to a callers's variable for local packages path 
# 4 - a valid path to a file to read 
read_config() {
    local -n remotes="$1" 
    local -n locals="$2"
    local -n local_packages_path="$3"
    local file_path="$4"

    # predefined config members
    local local_label_m=":local"
    local comment_m='#' # `#` starts a comment line in the config
    local path_m="path"

    while read -r line; do 
        local cleaned="$(echo "${line%%${comment_m}*}" | awk '{$1=$1};1')"          # clean of `#` and leading && trailing spaces
        if [[ ! -z "$cleaned" ]]; then               
            if [[ "$cleaned" =~ "$path_m" ]]; then     
                local_packages_path="${cleaned##*:}"
            fi
            if [[ "$cleaned" =~ "$local_label_m" ]]; then
                    locals+=("${cleaned%%:*}")
            elif [[ ! "$cleaned" =~ "path" ]]; then
                    remotes+=("${cleaned}")
            fi
        fi
    done < "$file_path"
}

get_package_name() {
    local res="$(dpkg-deb -I "$1" 2> /dev/null | grep "Package:")"
    echo "${res##* }"
}

get_package_version() {
    local res="$(dpkg-deb -I "$1" 2> /dev/null | grep "Version:")"
    echo "${res##* }"
}