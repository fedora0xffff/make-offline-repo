#!/bin/bash

repo_path="repo"
destination="dest"
apt_sources="/etc/apt/sources.list"

read_args() {
    local -n map="$1" 
    shift
    local args=("$@")

    for arg in "${args[@]}"; do 
        local arg_name="${arg%%=*}"
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

test_privileges() {
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root" 1>&2
        exit 1
    fi
}

usage() {
    echo """
Usage: <enable-repo.sh> <params>, 

params:

repo                        specify path to the directory containing repos (main, alternative)
dest                        specify path for repo installation (e.g., /var/distr)

Example: enable-repo.sh --repo=repo.tar.gz --dest=/var/distr

"""
}

main() {
    declare -A arg_map
    read_args arg_map "$@"

    # globals
    repos="${arg_map["$repo_path"]/"~"/"$HOME"}"
    dest="${arg_map["$destination"]/"~"/"$HOME"}"

    if [[ "${arg_map["help"]}" = "1" || ${#arg_map[@]} -eq 0 ]]; then
        usage && exit 0
    fi
    
    test_privileges 

    if [[ "$repos" =~ ".gz" ]]; then 
        if ! tar -xzf "$repos" > /dev/null 2>&1; then
            tar -xf "$repos"
        fi
        repos="${repos%%.*}"
        echo "$repos"
    fi

    [[ ! ${dest:0:1} = '/' ]] && dest="$(realpath $dest)"
    [[ ! -d "$dest" ]] && mkdir -p $dest > /dev/null 2>&1
          
    for repo in $repos/*; do
        echo "copying $repo to $dest..."
        cp -r "$repo" "$dest"
    done 

    echo "adding entries to $apt_sources:"
    for path in $(find "$dest" -name "Packages.gz"); do 
        local dir="$(dirname "$path")"
        echo "deb [trusted=yes] file:$dir ./" >> /etc/apt/sources.list
    done
}

main "$@"