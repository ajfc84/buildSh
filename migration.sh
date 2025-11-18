#!/bin/sh

environment_migration() {
    NEW_ORIGIN="$1"

    if [ -z "$NEW_ORIGIN" ]; then
        echo "ERROR: No new origin provided."
        echo "Usage: $1 <new-origin-url>"
        return 1
    fi

    # Ensure we are inside a git repo
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "ERROR: Not inside a git repository."
        return 1
    fi

    # Get current origin
    CURRENT_ORIGIN=$(git remote get-url origin 2>/dev/null)

    if [ -z "$CURRENT_ORIGIN" ]; then
        echo "ERROR: No origin remote set."
        return 1
    fi

    echo "Saving current origin as 'old'..."
    git remote remove old >/dev/null 2>&1  # ignore if it doesn't exist
    git remote add old "$CURRENT_ORIGIN"

    echo "Setting new origin: $NEW_ORIGIN"
    git remote remove origin >/dev/null 2>&1
    git remote add origin "$NEW_ORIGIN"

    echo "Pushing ALL branches to new origin..."
    git push origin --all
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to push branches."
        return 1
    fi

    echo "Pushing ALL tags to new origin..."
    git push origin --tags
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to push tags."
        return 1
    fi

    echo "Migration complete."
    echo "Old remote saved as: $CURRENT_ORIGIN"
    echo "New remote is now: $NEW_ORIGIN"
    echo "Please update the following main.yaml vars:"
    echo "CI_PROJECT_ID, CI_SERVER_URL, CI_REGISTRY, CI_PROJECT_PATH"
    echo "and secrets.yaml:"
    echo "REGISTRY_TOKEN"
}
