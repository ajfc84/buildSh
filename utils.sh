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
    BUILD_DIR="$1"

    if [ -z "$BUILD_DIR" ] ||  [ -z "$2" ];
    then
        echo "Usage: mk_build <BUILD_DIR> <SRC_DIRS...>" >&2
        exit 1
    fi

    BUILD_DIR="${SUB_PROJECT_DIR}/${BUILD_DIR}"

    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"

    shift
    for sub in "$@"; do
        src_dir="${SUB_PROJECT_DIR}/$sub"

        if [ ! -d "$src_dir" ]; then
            echo "Error: directory '$src_dir' not found" >&2
            exit 1
        fi

        cp -R "$src_dir"/. "$BUILD_DIR/"
    done
}
