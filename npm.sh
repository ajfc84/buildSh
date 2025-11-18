#!/bin/sh


npm_build() {
    SRC_DIR="$1"
    BUILD_DIR="$2"

    if [ -z "$SRC_DIR" ] || [ -z "$BUILD_DIR" ];
    then
        echo "Usage: $0 <SRC_DIR> <BUILD_DIR>" >&2
        exit 1
    fi

    SRC_DIR="${SUB_PROJECT_DIR}/${SRC_DIR}"
    BUILD_DIR="${SUB_PROJECT_DIR}/build/${BUILD_DIR}"

    if [ ! -d "$SRC_DIR" ];
    then
        echo "Error: directory '$SRC_DIR' not found" >&2
        return 1
    fi

    echo "INFO: $0 removing old build"
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"

    echo "Running npm install and Vite build in $SRC_DIR"
    (cd "$SRC_DIR" && npm install && npx vite build --outDir "$BUILD_DIR") || {
        echo "Error: failed to build React project with Vite"
        return 1
    }


    echo "INFO: cleaning node_modules"
    rm -rf "$SRC_DIR/node_modules"
}
