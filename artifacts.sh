#!/bin/sh


upload_artifacts()
{
    SOURCE_DIR="$1"
    REMOTE_DIR="$2"
    SRC_TYPE="$3"
    shift 3

    if [ -z "$SOURCE_DIR" ] ||  [ -z "$REMOTE_DIR" ] ||  [ -z "$SRC_TYPE" ];
    then
        echo "Usage: $0 <SOURCE_DIR> <REMOTE_DIR> <SRC_TYPE> <file1> <file2> ..." >&2
        exit 1
    fi

    if [ -z "$STORAGE_URL" ] ||  [ -z "$STORAGE_USER" ];
    then
        echo "ERROR: $0 requires environment variables: STORAGE_URL, STORAGE_USER" >&2
        exit 1
    fi

    echo "INFO: Uploading distribution archive..."

    if [ "$SRC_TYPE" = "linux" ];
    then
        SOURCE_DIR="${SUB_PROJECT_DIR}/${SOURCE_DIR}"
    elif [ "$SRC_TYPE" = "windows" ];
    then
        SOURCE_DIR="/mnt/c/${SOURCE_DIR}"
    else
        echo "ERROR: $0 invalid: SRC_TYPE=$SRC_TYPE" >&2
        exit 1
    fi

    echo "Uploading artifacts to $STORAGE_URL:$REMOTE_DIR"

    ssh "${STORAGE_USER}@$STORAGE_URL" "mkdir -p '$REMOTE_DIR'"

    for a in "$@"; do
        artifact="${SOURCE_DIR}/$a"
        if [ ! -e "$artifact" ]; then
            echo "Skipping missing artifact: $artifact" >&2
            continue
        fi
        echo "Uploading: $artifact"
        scp -r "$artifact" "${STORAGE_USER}@$STORAGE_URL:$REMOTE_DIR/"
    done

    echo "Artifacts uploaded successfully to $STORAGE_URL:$REMOTE_DIR"
}
