#!/bin/bash
dir="$(dirname "$0")"
source "$dir/common/printer.sh"
source "$dir/common/read_args.sh"
source "$dir/common/packages_config.sh"

#option names
config="config"
out_dir="out-dir"
verbose="verbose"
skip_errors="skip-errors"
update_cmp="sudo apt update"
enable_i386="sudo dpkg --add-architecture i386"

# for the main repos
main_repo="repo_main"
# for the duplicating packages but with a different version
alternative="repo_alternative"

usage() {
    echo """
Usage: <make_local_repo.sh> <params>, 

params:

config                      specify path to the file containig required packages list
out-dir                     specify path to directory (which will be created if it doesn't exist) where the new local repo will be created
skip-errors (optional)      specify to continue downloading packages even if an error occurred 

Example: make_local_repo.sh --config=packages.txt --out-dir=~/repo_dir/WINE-kubuntu --skip-errors

"""
}

# depends on global vars:
# - `archs`
# - `out`
# (!) The repo supports max 2 versions of the same package.
# One will be moved to `main` and if there is another one with 
# a different version, it will be moved to `alternative`
# Packages of the same name for different architectures are ok
prepare_repo() {
    local path="$1"
    for arch in "${archs[@]}"; do
        mkdir -p "$path/$arch" > /dev/null 2>&1
    done

    local added_package_names=()

    for filename in ${out}/*; do
        local pack_name="$(get_package_name "$filename")"
        for arch in "${archs[@]}"; do
            # if a package name has already been added to the current repo,
            # leave it. It will be moved to the `alternative/$arch` on the next iteration 
            if [[ "$filename" =~ "$arch" && ! -d "$filename" ]]; then
                if [[ ! "${added_package_names[@]}" =~ "${pack_name}_${arch}" ]]; then
                    if mv "$filename" "$path/$arch" > /dev/null 2>&1; then 
                        added_package_names+=("${pack_name}_${arch}")
                    fi
                elif [[ ! -d "$out/$alternative" ]]; then 
                    mkdir -p "$out/$alternative"
                fi
            fi
        done
    done

    # index packages in each repo 
    for arch in "${archs[@]}"; do
        print_message "Indexing packages in $path/$arch..."
        pushd $path/$arch > /dev/null
        dpkg-scanpackages . | gzip -9c > "Packages.gz"
        popd > /dev/null
    done
}

# depends on global vars:
# - `failed_to_load`
# - `skip_err`
# - `out`
download_package_and_deps() {
    local failed=()

    print_message "Dowloading $1 and its dependencies..."
    pushd "$out" > /dev/null
    for package in $(apt-rdepends "$1" 2> /dev/null | grep -v "^ "); do 
        if ! apt-get download $package > /dev/null 2>&1; then
            [[ ! "$package" = "$1" ]] && failed+=("$1")
        fi
    done
    if [[ ${#failed[@]} -ne 0 ]]; then
        print_message "Some $1 deps were not downloaded" w
        failed_to_load+=("$1")
        print_array failed
    else 
        print_message "$1 and its deps were downloaded" i
    fi
    popd > /dev/null
}

# depends on global vars:
# - `package_path`
# - `out`
add_local_package() {
    local package="$1"
    local path="$(find "$package_path/" -iname "$package*")"
    [[ "$verbosity" = 1 ]] && print_message "path for $package is $path"
    cp $path $out
}

check_package_utils() {
    local utils=("dpkg-scanpackages" "apt-rdepends" "gzip")
    for util in "${utils[@]}"; do 
        if ! which "$util" > /dev/null 2>&1; then
            print_message "$util is missing! Trying to install dpkg-dev..."
            if ! sudo apt install -y $util > /dev/null 2>&1; then 
                    pretty_error "Failed to install $util, cannot proceed"
            fi
        fi
    done
}

main() {
    declare -A arg_map
    read_args arg_map "$@"

    # globals
    config_file="${arg_map["$config"]/"~"/"$HOME"}"
    out="${arg_map["$out_dir"]/"~"/"$HOME"}"
    skip_err=${arg_map["$skip_errors"]}
    verbosity=${arg_map["$verbose"]}

    archs=("amd64" "all")
    package_path=""     # local packages path
    failed_to_load=()   # packages that were not downloaded
    remote_packages=()  # packages to download from a remote repo
    local_packages=()   # packages that are stored in data/local_packages
    multiversion=()
    out_paths=("$out/$main_repo") # "$out/$alternative" is added in case there are more than one versions of a package

    if [[ "${arg_map["help"]}" = "1" ]]; then
        usage && exit 0
    fi

    [[ ! -f "$config_file" ]] && pretty_error "Invalid package config path: $config_file, exitting"
    [[ ! -d "$out" ]] && mkdir -p $out > /dev/null 2>&1

    read_config remote_packages local_packages package_path "$config_file"

    if [[ "${remote_packages[@]}" =~ "i386"  || "${local_packages[@]}" =~ "i386" ]]; then
        sudo dpkg --add-architecture i386
        archs+=("i386")
    fi

    if [[ $verbosity = "1" ]]; then 
        print_message "remote packages:"
        print_array remote_packages
        print_message "local packages:"
        print_array local_packages
        print_message "archs:"
        print_array archs
        print_message "path to local repo:"
        echo "\`$package_path\`"
    fi

    print_message "updating package index..."
    if ! sudo apt update > /dev/null 2>&1; then 
        print_message "apt update failed! Continue [y/n]?" e
        read ans
        if [[ "$ans" = @(n|N) ]]; then 
            exit 1
        fi
    fi

    check_package_utils

    # add locals
    for package in "${local_packages[@]}"; do 
        add_local_package "$package"
    done
    # download remotes
    for package in "${remote_packages[@]}"; do 
        download_package_and_deps "$package"
    done
    mkdir -p $out/$main_repo
    prepare_repo $out/$main_repo
    if [[ -d "$out/$alternative" ]]; then 
        prepare_repo "$out/$alternative"
    fi
    tar -czf "${out}.tag.gz" ${out}

    if [[ ${#failed_to_load[@]} -ne 0 ]]; then 
        print_message "The following packages were not downloaded or have unresolved dependencies:" w
        for failed in "${failed_to_load[@]}"; do
            echo "-> $failed"
        done
    else 
        print_message "Package repository $out is ready!" i
    fi
}

main "$@"


