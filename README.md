# makeOfflineRepo
This repo provides a script to create a specific offline package repo for a debian-based Linux OS

# Usage
## Create a repo 

To create an offline package repository, create a list of packages needed as in example in `data/packages_list_example.txt` and
use a command as follows: 

`make_local_repo.sh --config=packages.txt --out-dir="path/to/repo/<repo_name>"`

If a path `path/to/repo/<repo_name>` does not exist, it will be created.

For more info on options, see `make_local_repo.sh --help`

## Enable a created repo via script
Use `enable-repo.sh` to move repo files to a suitable location and include to `/etc/apt/sources.list`: 

`enable-repo.sh --repo=<repo_path> --dest=<repo_store_path>`

See `enable-repo.sh --help` for more info.

## About repos created by this script
The script `make_local_repo.sh` creates directories `repo_main` (main package versions) and `repo_alternative` (in case there are same packages but of different version).
Each directory includes subdirs `amd64`, `all` (and `i386` if there are packages on the list specified like `<package>:i386`). So the repo tree looks like:
```
├── repo_alternative
│   ├── amd64
│   └── i386
└── repo_main
    ├── all
    ├── amd64
    └── i386
```
The repos need to be added to `/etc/apt/sources.list` as follows:

`deb [trusted=yes] file:<absolute_local_repo_path> ./`

E.g., for the tree above:
```
deb [trusted=yes] file:/<abs_path>/repo_main/amd64 ./
deb [trusted=yes] file:/<abs_path>/repo_main/i386 ./
deb [trusted=yes] file:/<abs_path>/repo_main/all ./
deb [trusted=yes] file:/<abs_path>/repo_alternative/amd64 ./
deb [trusted=yes] file:/<abs_path>/repo_alternative/i386 ./
```

## TODO
- support RPM