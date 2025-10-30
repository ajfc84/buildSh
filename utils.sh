#!/bin/sh


read_passwd()
{
  stty -echo
  printf "${1}: "
  read ${1}
  printf "\n"
  stty echo
}

mk_build()
{
    build_dir="${SUB_PROJECT_DIR}/$1"
    shift

    rm -rf "$build_dir"
    mkdir -p "$build_dir"

    for sub in "$@"; do
        src_dir="${CI_PROJECT_DIR}/$sub"

        if [ ! -d "$src_dir" ]; then
            echo "Error: directory '$src_dir' not found" >&2
            return 1
        fi

        cp -R "$src_dir"/. "$build_dir/"
    done
}
