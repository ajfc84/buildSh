#!/bin/sh


collectstatic()
{
    PROJECT_NAME="$1"

    if [ ! -d "${SUB_PROJECT_DIR}/.venv" ];
    then
        python3 -m venv "${SUB_PROJECT_DIR}/.venv"
    fi
    . "${SUB_PROJECT_DIR}/.venv/bin/activate"
    pip3 install -r "${SUB_PROJECT_DIR}/${PROJECT_NAME}/requirements.txt"
    python3 "${SUB_PROJECT_DIR}/${PROJECT_NAME}/manage.py" collectstatic --noinput
}

runserver()
{
    HOST="$1"
    PORT="$2"

    if [ -z "$HOST" ] ||  [ -z "$PORT" ];
    then
        echo "Usage: $0 <HOST> <PORT>" >&2
        exit 1
    fi

    if [ -z "$SUB_PROJECT_DIR" ] || [ -z "$CI_PROJECT_NAME" ];
    then
        echo "ERROR: $0 requires environment variables: SUB_PROJECT_DIR, CI_PROJECT_NAME" >&2
        exit 1
    fi

    if [ ! -d "${SUB_PROJECT_DIR}/.venv" ];
    then
        echo "ERROR: $0 no python environment found." >&2
    fi

    echo "INFO: stopping ${CI_PROJECT_NAME} container" >&2
    if [ "$(docker ps | grep -c ${CI_PROJECT_NAME})" -gt 0 ];
    then
        docker stop "${CI_PROJECT_NAME}"
    fi

    echo "INFO: activating python environment" >&2
    . "${SUB_PROJECT_DIR}/.venv/bin/activate"

    echo "INFO: starting python server" >&2
    python3 "${SUB_PROJECT_DIR}/${CI_PROJECT_NAME}-api/manage.py" runserver $HOST:$PORT

    echo "INFO: deactivating python environment" >&2
    deactivate
}
