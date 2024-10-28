# makeOfflineRepo
This repo provides a script to create a specific offline package repo for a debian-based Linux OS (in future, rpm support will be added) 

## Usage

To create an offline package repository, create a list of packages needed as in example in `data/packages_list_example.txt` and
use a command as follows: 

`make_local_repo.sh --config=packages.txt --out-dir="path/to/repo/<repo_name>"`

If a path `path/to/repo/<repo_name>` does not exist, it will be created.

For more info on options, see `make_local_repo.sh --help`

## TODO
- support RPM