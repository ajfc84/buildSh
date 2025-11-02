#!/bin/sh

go_build()
{
    PROJECT_NAME="$1"
    SRC="$2"
    DIST="$3"

    if [ -z "$PROJECT_NAME" ] ||  [ -z "$SRC" ] ||  [ -z "$DIST" ];
    then
        echo "Usage: go_build <PROJECT_NAME> <SRC> <DIST>" >&2
        exit 1
    fi

    SRC="${SUB_PROJECT_DIR}/${SRC}"
    DIST="${SUB_PROJECT_DIR}/${DIST}"

    echo "INFO: Installing Go dependencies..."
    go -C "${SRC}" mod tidy
    go -C "${SRC}" mod download

    echo "INFO: Building for Linux amd64..."
    GOOS=linux GOARCH=amd64 go -C "${SRC}" build -o "${DIST}/${PROJECT_NAME}" .
    chmod +x "${DIST}/${PROJECT_NAME}"

    echo "INFO: Building for Windows amd64..."
    GOOS=windows GOARCH=amd64 go -C "${SRC}" build -o "${DIST}/${PROJECT_NAME}.exe" .
}

go_zip()
{
    BUILD_DIR="$1"
    BIN_NAME="$2"

    if [ -z "$BUILD_DIR" ] ||  [ -z "$BIN_NAME" ];
    then
        echo "Usage: go_zip <BUILD_DIR> <BIN_NAME>" >&2
        exit 1
    fi

    if [ -z "$CI_PROJECT_NAME" ] ||  [ -z "$IMAGE_VERSION" ];
    then
        echo "ERROR: go_zip requires environment variables: CI_PROJECT_NAME, IMAGE_VERSION" >&2
        exit 1
    fi

    BUILD_DIR="${SUB_PROJECT_DIR}/${BUILD_DIR}"

    echo "INFO: Creating distribution archive..."
    zip -j "${BUILD_DIR}/${CI_PROJECT_NAME}-v${IMAGE_VERSION}.zip" "${BUILD_DIR}/${BIN_NAME}" "${BUILD_DIR}/${BIN_NAME}.exe"
    echo "INFO: distribution archive ${CI_PROJECT_NAME}-v${IMAGE_VERSION}.zip created"
}