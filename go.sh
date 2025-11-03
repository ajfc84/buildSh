#!/bin/sh

go_build()
{
    BIN_NAME="$1"
    SRC="$2"
    DIST="$3"

    if [ -z "$BIN_NAME" ] ||  [ -z "$SRC" ] ||  [ -z "$DIST" ];
    then
        echo "Usage: $0 <BIN_NAME> <SRC> <DIST>" >&2
        exit 1
    fi

    SRC="${SUB_PROJECT_DIR}/${SRC}"
    DIST="${SUB_PROJECT_DIR}/${DIST}"

    echo "INFO: Installing Go dependencies..."
    go -C "${SRC}" mod tidy
    go -C "${SRC}" mod download

    echo "INFO: Building for Linux amd64..."
    GOOS=linux GOARCH=amd64 go -C "${SRC}" build -o "${DIST}/${BIN_NAME}" .
    chmod +x "${DIST}/${BIN_NAME}"
}

go_build_win()
{
    PROJECT_NAME="$1"
    SRC="$2"

    if [ -z "$PROJECT_NAME" ] ||  [ -z "$SRC" ];
    then
        echo "Usage: $0 <PROJECT_NAME> <SRC>" >&2
        exit 1
    fi

    SRC="${SUB_PROJECT_DIR}/${SRC}"
    DISPLAY_NAME=$(to_camel_case "${PROJECT_NAME}")
    DIST_WIN="/mnt/c/${DISPLAY_NAME}"

    echo "INFO: Installing Go dependencies..."
    go -C "${SRC}" mod tidy
    go -C "${SRC}" mod download

    echo "INFO: Building for Windows amd64..."
    GOOS=windows GOARCH=amd64 go -C "${SRC}" build -o "${DIST_WIN}/${PROJECT_NAME}.exe" .
}

go_zip()
{
    BUILD_DIR="$1"
    BIN_NAME="$2"

    if [ -z "$BUILD_DIR" ] ||  [ -z "$BIN_NAME" ];
    then
        echo "Usage: $0 <BUILD_DIR> <BIN_NAME>" >&2
        exit 1
    fi

    if [ -z "$CI_PROJECT_NAME" ] ||  [ -z "$IMAGE_VERSION" ];
    then
        echo "ERROR: $0 requires environment variables: CI_PROJECT_NAME, IMAGE_VERSION" >&2
        exit 1
    fi

    BUILD_DIR="${SUB_PROJECT_DIR}/${BUILD_DIR}"

    echo "INFO: Creating distribution archive..."
    zip -j "${BUILD_DIR}/${CI_PROJECT_NAME}-v${IMAGE_VERSION}.zip" "${BUILD_DIR}/${BIN_NAME}"
    echo "INFO: distribution archive ${CI_PROJECT_NAME}-v${IMAGE_VERSION}.zip created"
}