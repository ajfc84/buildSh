#!/bin/sh

go_build()
{
    PROJECT_NAME="$1"
    DIST="${SUB_PROJECT_DIR}/$2"

    if [ -z "$PROJECT_NAME" ] ||  [ -z "$DIST" ];
    then
        echo "Usage: go_build <PROJECT_NAME> <DIST>" >&2
        return 1
    fi

    SRC="${SUB_PROJECT_DIR}/${PROJECT_NAME}"

    echo "INFO: Installing Go dependencies..."
    go -C "${SRC}" mod tidy
    go -C "${SRC}" mod download

    echo "INFO: Building for Linux amd64..."
    GOOS=linux GOARCH=amd64 go -C "${SRC}" build -o "${DIST}/${PROJECT_NAME}" .
    chmod +x "${DIST}/${PROJECT_NAME}"

    echo "INFO: Building for Windows amd64..."
    GOOS=windows GOARCH=amd64 go -C "${SRC}" build -o "${DIST}/${PROJECT_NAME}.exe" .
}
