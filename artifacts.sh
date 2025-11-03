#!/bin/sh


upload_artifacts()
{
    SOURCE_DIR="$1"
    REMOTE_DIR="$2"
    shift 2

    if [ -z "$SOURCE_DIR" ] ||  [ -z "$REMOTE_DIR" ];
    then
        echo "Usage: $0 upload_artifacts <SOURCE_DIR> <REMOTE_DIR> <file1> <file2> ..." >&2
        exit 1
    fi

    if [ -z "$CI_REPOSITORY_URL" ] ||  [ -z "$CI_REPOSITORY_USER" ];
    then
        echo "ERROR: $0 requires environment variables: CI_REPOSITORY_URL, CI_REPOSITORY_USER" >&2
        exit 1
    fi

    echo "INFO: Uploading distribution archive..."

    SOURCE_DIR="${SUB_PROJECT_DIR}/${SOURCE_DIR}"

    echo "Uploading artifacts to $CI_REPOSITORY_URL:$REMOTE_DIR"

    ssh "${CI_REPOSITORY_USER}@$CI_REPOSITORY_URL" "mkdir -p '$REMOTE_DIR'"

    for a in "$@"; do
        artifact="${SOURCE_DIR}/$a"
        if [ ! -e "$artifact" ]; then
            echo "Skipping missing artifact: $artifact" >&2
            continue
        fi
        echo "Uploading: $artifact"
        scp -r "$artifact" "${CI_REPOSITORY_USER}@$CI_REPOSITORY_URL:$REMOTE_DIR/"
    done

    echo "Artifacts uploaded successfully to $CI_REPOSITORY_URL:$REMOTE_DIR"
}
