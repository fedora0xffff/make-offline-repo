#!/bin/bash

demo_repo="data/demo_repo"
demo_list="data/packages_list_example.txt"

echo "Creating a demo repo by the list: data/packages_list_example.txt"
./make_local_repo.sh --config="$demo_list" --out-dir="$demo_repo" --skip-errors

if [[ -d $(realpath $demo_repo) ]]; then
    echo "Demo repo created at: $demo_repo"
else
    echo "Failed to create demo repo"
fi  