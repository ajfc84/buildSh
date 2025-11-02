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

uuidgen_safe() {
    if command -v uuidgen >/dev/null 2>&1; then
        uuidgen
    else
        echo "00000000-0000-0000-0000-`date +%s`"
    fi
}

to_camel_case() {
    input=$1
    output=""
    IFS='-_'
    for part in $input; do
        first=`printf "%s" "$part" | cut -c1 | tr '[:lower:]' '[:upper:]'`
        rest=`printf "%s" "$part" | cut -c2- | tr '[:upper:]' '[:lower:]'`
        output="${output}${first}${rest}"
    done
    unset IFS
    printf "%s\n" "$output"
}
