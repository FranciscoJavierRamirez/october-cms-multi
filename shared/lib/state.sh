# shared/lib/state.sh
#!/bin/bash

STATE_DIR="${PROJECT_ROOT}/.october-state"
mkdir -p "$STATE_DIR"

save_state() {
    local version=$1
    local key=$2
    local value=$3
    echo "$value" > "$STATE_DIR/${version}-${key}"
}

get_state() {
    local version=$1
    local key=$2
    local default=${3:-""}
    
    if [ -f "$STATE_DIR/${version}-${key}" ]; then
        cat "$STATE_DIR/${version}-${key}"
    else
        echo "$default"
    fi
}

is_installed() {
    local version=$1
    [ "$(get_state "$version" "installed")" == "true" ]
}

mark_installed() {
    local version=$1
    save_state "$version" "installed" "true"
    save_state "$version" "installed_at" "$(date -u +"%Y-%m-%d %H:%M:%S")"
}