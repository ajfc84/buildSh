#!/bin/sh


upload_artifacts()
{
    if [ "$#" -eq 0 ]; then
        echo "ERROR: no artifact filenames provided" >&2
        echo "Usage: $0 upload_artifacts <file1> <file2> ..." >&2
        exit 1
    fi
    echo "INFO: Uploading distribution archive..."

    HOST=${CI_REPOSITORY_URL}
    USERNAME=${CI_REPOSITORY_USER}

    SOURCE_DIR="${SUB_PROJECT_DIR}/$1"
    REMOTE_DIR="$2"
    shift 2

    echo "Uploading artifacts to $HOST:$REMOTE_DIR"

    ssh "${USERNAME}@$HOST" "mkdir -p '$REMOTE_DIR'"

    for a in "$@"; do
        artifact="${SOURCE_DIR}/$a"
        if [ ! -e "$artifact" ]; then
            echo "Skipping missing artifact: $artifact" >&2
            continue
        fi
        echo "Uploading: $artifact"
        scp -r "$artifact" "${USERNAME}@$HOST:$REMOTE_DIR/"
    done

    echo "Artifacts uploaded successfully to $HOST:$REMOTE_DIR"
}
