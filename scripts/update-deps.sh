#!/bin/bash

# Update dependency locks for each subproject in the activitywatch repo

set -e
set -x

SUBPROJECTS="aw-core aw-client aw-qt aw-server aw-server-rust aw-notify aw-tauri/src-tauri aw-watcher-afk aw-watcher-window aw-watcher-input awatcher"

for subproject in $SUBPROJECTS; do
    # Go to subproject
    cd $subproject

    # Update dependency locks
    # Use poetry if poetry.lock exists, or cargo if Cargo.toml exists
    if [ -f "poetry.lock" ]; then
        poetry update
    elif [ -f "Cargo.toml" ]; then
        cargo update
    fi

    # Go back to root
    cd - > /dev/null
done

