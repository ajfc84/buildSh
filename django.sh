#!/bin/sh


collectstatic()
{
    PROJECT_NAME="$1"

    if [ ! -d "${SUB_PROJECT_DIR}/.venv" ];
    then
        python3 -m venv "${SUB_PROJECT_DIR}/.venv"
    fi
    . "${SUB_PROJECT_DIR}/.venv/bin/activate"
    python3 "${SUB_PROJECT_DIR}/${PROJECT_NAME}/manage.py" collectstatic --noinput
}
