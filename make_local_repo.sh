#!/bin/bash
dir="$(dirname "$0")"
source "$dir/common/printer.sh"
source "$dir/common/read_args.sh"

#option names
config="config"
out_dir="out-dir"
skip_errors="skip-errors"

usage() {
    echo """
Usage: <make_local_repo.sh> <params>, 
This script creates a local .deb packages repo from the list of packages listed in the provided \`config\` file.
params:

config                      specify path to the file containig required packages list
out-dir                     specify path to directory (which will be created if it doesn't exist) where the new local repo will be created
skip-errors (optional)      specify to continue downloading packages even if an error occurred 
verbose (optional)          specify to enable verbose mode

Example: make_local_repo.sh --config=packages.txt --out-dir=~/repo_dir/<repo_name> --skip-errors

"""
}

prepare_repo() {
    for arch in "${archs[@]}"; do
        mkdir "$out/$arch" > /dev/null 2>&1
    done

    for filename in ${out}/*; do
        for arch in "${archs[@]}"; do
            if [[ "$filename" =~ "$arch" && ! -d "$filename" ]]; then
                mv "$filename" "$out/$arch" > /dev/null 2>&1
            fi
        done
    done

    for arch in "${archs[@]}"; do
        print_message "Indexing packages in "$out/$arch"..."
        dpkg-scanpackages "$out/$arch" | gzip -9c > "$out/$arch/Packages.gz"
    done
}

read_packages() {
    while read -r package; do 
        packages+=("$package")
    done < "$config_file"

    if [[ ${#packages[@]} -eq 0 ]]; then 
        pretty_error "No packages read, exitting"
    fi 
    
    print_message "Read packages from config:"
    print_array "packages"
}

download_package_and_deps() {
    sudo apt clean
    if ! sudo apt --download-only install "$1" -y > /dev/null 2>&1; then 
        print_message "Failed to download package $1"
        [[ ! $skip_err = "1" ]] && exit 1
        failed_to_load+=("$1")
    else 
        cp /var/cache/apt/archives/*.deb "$out" > /dev/null 2>&1
    fi
}

main() {
    declare -A arg_map
    read_args arg_map "$@"

    # globals
    config_file="${arg_map["$config"]/"~"/"$HOME"}"
    out="${arg_map["$out_dir"]/"~"/"$HOME"}"
    skip_err=${arg_map["$skip_errors"]}
    archs=("amd64" "all")
    failed_to_load=()
    packages=()

    if [[ "${arg_map["help"]}" = "1" ]]; then
        usage && exit 0
    fi

     if ! which dpkg-scanpackages > /dev/null 2>&1; then
        print_message "dpkg-scanpackages is missing! Trying to install dpkg-dev..."
        sudo apt update
        if ! sudo apt install dpkg-dev -y; then 
             pretty_error "Failed to install dpkg-dev, cannot proceed"
        fi
    fi

    [[ ! -f "$config_file" ]] && pretty_error "Invalid package config path: $config_file, exitting"
    [[ ! -d "$out" ]] && mkdir -p $out > /dev/null 2>&1

    read_file_to_array packages "$config_file" "#"
    if [[ "${packages[@]}" =~ "i386" ]]; then
        sudo dpkg --add-architecture i386
        archs+=("i386")
    fi

    sudo apt update
    for package in "${packages[@]}"; do 
        download_package_and_deps "$package"
    done

    prepare_repo
    if [[ ${#failed_to_load[@]} -ne 0 ]]; then 
        print_message "The following packages were not downloaded:"
        for $failed in "${failed_to_load[@]}"; do
            echo "$failed"
        done
    else 
        print_message "Package repository $out is ready!" i
    fi
}

main "$@"


