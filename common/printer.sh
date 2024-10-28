#!/bin/bash 

YELLOW='\033[0;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# print a message in a specified information level
# 1 - a message text
# 2 - mode to display a message in: 
#
# i - info, 
# e - error, 
# no param - usual
print_message () {
    local message="$1"
    local mode="$2"

    if [[ ! -z "$1" ]]; then
        case $mode in
        i) echo -e "${GREEN}[INFO] $1${NC}" ;;
        e) echo -e "${RED}[ERROR] $1${NC}" ;;
        w) echo -e "${YELLOW}[WARNING] $1${NC}" ;;
        *) echo -e "[STATUS] $1" ;;
        esac
    fi
}

pretty_error() {
    print_message "$*" e > /dev/stderr && exit 1
}

print_array() {
    declare -n out="$1"
    local ctr=1
    for elem in "${out[@]}"; do 
        echo "#$ctr: $elem"
        ((ctr++))
    done
}

print_map() {
    declare -n out="$1"
    local ctr=1
    for key in "${!out[@]}"; do 
        echo "#$ctr: $key = ${out[$key]}"
        ((ctr++))
    done
}