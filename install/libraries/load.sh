#!/usr/bin/env bash
#
# ==============================================================================
# NetCore Library Loader
# ==============================================================================
# Loads all shared NetCore framework libraries.
#
# ==============================================================================

set -Eeuo pipefail


if [[ -z "${NETCORE_ROOT:-}" ]]; then
    NETCORE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi


readonly NETCORE_LIBRARY_DIR="${NETCORE_ROOT}/install/libraries"


NETCORE_LIBRARIES=(

    "logging.sh"
    "commands.sh"
    "packages.sh"
    "services.sh"
    "filesystem.sh"
    "network.sh"
    "system.sh"

)


load_netcore_libraries() {

    local LIBRARY
    local LIBRARY_PATH

    for LIBRARY in "${NETCORE_LIBRARIES[@]}"; do

        LIBRARY_PATH="${NETCORE_LIBRARY_DIR}/${LIBRARY}"

        if [[ ! -f "$LIBRARY_PATH" ]]; then
            echo "[FAIL] Required NetCore library not found: $LIBRARY_PATH" >&2
            return 1
        fi

        # shellcheck source=/dev/null
        source "$LIBRARY_PATH"

    done

}


load_netcore_libraries
