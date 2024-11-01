#!/bin/bash

show() {
    local -n out="$1"
    for key in "${!out[@]}"; do 
        echo "$key = ${out[$key]}"
    done
}

# 1 - arguments map reference from the caller
# 2 - a sequence of key/value like: --param1=value1 --param2=value2
read_args() {
    local -n map="$1" 
    shift
    local args=("$@")

    for arg in "${args[@]}"; do 
        local arg_name="${arg%%=*}"
        # cut the leading '--', discard otherwise
        if [[ "${arg:0:2}" = "--" ]]; then 
            local value=""
            if [[ "$arg" =~ "=" ]]; then 
                value="${arg##*=}"
            else 
                value="1"
            fi
            map["${arg_name:2}"]="$value"
        fi
    done

}

# 1 - a reference to a caller's array
# 2 - a valid path to a file to read 
# 3 - optionally, provide a comment start char (like '#' or '/')
read_file_to_array() {
    local -n out_array="$1"
    local file_path="$2"
    local comment="$3"

    while read -r item; do 
        if [[ ! -z "$comment" ]]; then 
            local cleaned="${item%%#*}"
            [[ ! -z "$cleaned" ]] && out_array+=("$cleaned")
        else 
            out_array+=("$item")
        fi
    done < "$file_path"
}
