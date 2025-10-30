#!/bin/sh


git_user_name() {
    name="$(git config --get user.name 2>/dev/null || true)"
    if [ -z "$name" ]; then
        name="$(git config --global --get user.name 2>/dev/null || true)"
    fi
    printf "%s" "$name"
}

git_user_email() {
    email="$(git config --get user.email 2>/dev/null || true)"
    if [ -z "$email" ]; then
        email="$(git config --global --get user.email 2>/dev/null || true)"
    fi
    printf "%s" "$email"
}
