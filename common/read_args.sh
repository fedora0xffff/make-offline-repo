#!/bin/bash

show() {
    declare -n out="$1"
    for key in "${!out[@]}"; do 
        echo "$key = ${out[$key]}"
    done
}

# 1 - a map reference from the caller
# 2 - a sequence of key/value like: --param1=value1 --param2=value2
read_args() {
    declare -n map="$1" 
    shift
    local args=("$@")

    for arg in "${args[@]}"; do 
        local arg_name="${arg%%=*}"
        # cut the leading '--', discard otherwise
        if [[ "${arg:0:2}" = "--" ]]; then 
            local value="${arg##*=}"
            [[ -z "${value}" ]] && value="1"
            map["${arg_name:2}"]="$value"
        fi
    done

    show map
}
