#!/bin/sh


sanitize_version() {
    version=$1
    # remove everything except digits and dots
    clean=$(printf "%s" "$version" | tr -cd '0-9.')

    # make sure it has 4 numeric parts (x.x.x.x)
    count=$(printf "%s" "$clean" | awk -F. '{print NF}')
    while [ "$count" -lt 4 ]; do
        clean="${clean}.0"
        count=$(expr "$count" + 1)
    done

    printf "%s\n" "$clean"
}
