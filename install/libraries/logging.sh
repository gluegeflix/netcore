#!/usr/bin/env bash
#
# ==============================================================================
# NetCore Logging Library
# ==============================================================================
# Shared logging and display helpers for the NetCore installer framework.
#
# Loaded by:
#   install/libraries/load.sh
#
# ==============================================================================

set -Eeuo pipefail

if [[ "${NETCORE_LOGGING_LIBRARY_LOADED:-false}" == true ]]; then
    return 0
fi

NETCORE_LOGGING_LIBRARY_LOADED=true
export NETCORE_LOGGING_LIBRARY_LOADED

################################################################################
# Logging Variables
################################################################################

LOG_DIR="${LOG_DIR:-}"
LOG_FILE="${LOG_FILE:-}"


################################################################################
# Colors
################################################################################

RED="${RED:-\033[0;31m}"
GREEN="${GREEN:-\033[0;32m}"
YELLOW="${YELLOW:-\033[1;33m}"
BLUE="${BLUE:-\033[0;34m}"
CYAN="${CYAN:-\033[0;36m}"
NC="${NC:-\033[0m}"


################################################################################
# Logging Initialization
################################################################################

init_logging() {

    if [[ $EUID -eq 0 ]]; then
        LOG_DIR="/var/log/netcore"
    else
        LOG_DIR="${NETCORE_ROOT}/logs"
    fi

    mkdir -p "$LOG_DIR"

    LOG_FILE="${LOG_DIR}/install.log"

    if ! touch "$LOG_FILE" 2>/dev/null; then
        LOG_DIR="${NETCORE_ROOT}/logs"

        mkdir -p "$LOG_DIR"

        LOG_FILE="${LOG_DIR}/install.log"
        touch "$LOG_FILE"
    fi

    export LOG_DIR
    export LOG_FILE

}


################################################################################
# Internal Logger
################################################################################

write_log() {

    local LEVEL="$1"
    shift

    local MESSAGE="$*"
    local TIME

    TIME=$(date "+%Y-%m-%d %H:%M:%S")

    if [[ -n "${LOG_FILE:-}" ]]; then
        printf '%s [%s] %s\n' \
            "$TIME" \
            "$LEVEL" \
            "$MESSAGE" \
            >> "$LOG_FILE" 2>/dev/null || true
    fi

}


################################################################################
# Public Log Functions
################################################################################

log_info() {

    write_log "INFO" "$*"
    printf '%b[INFO]%b %s\n' "$BLUE" "$NC" "$*"

}


log_success() {

    write_log "OK" "$*"
    printf '%b[ OK ]%b %s\n' "$GREEN" "$NC" "$*"

}


log_warn() {

    write_log "WARN" "$*"
    printf '%b[WARN]%b %s\n' "$YELLOW" "$NC" "$*"

}


log_error() {

    write_log "FAIL" "$*"
    printf '%b[FAIL]%b %s\n' "$RED" "$NC" "$*" >&2

}


################################################################################
# Step Display
################################################################################

step() {

    local MESSAGE="${1:-}"

    echo
    echo "------------------------------------------------------"
    echo "$MESSAGE"
    echo "------------------------------------------------------"

}


################################################################################
# Module Display
################################################################################

module_start() {

    local MODULE_NAME="${1:-Unnamed Module}"

    step "Starting ${MODULE_NAME}"

}


module_finish() {

    local MODULE_NAME="${1:-Unnamed Module}"

    log_success "${MODULE_NAME} completed."

}


################################################################################
# Banner
################################################################################

print_banner() {

    cat <<EOF

======================================================
              NetCore Installer
                 Version ${NETCORE_VERSION}
======================================================

NetCore Root:
${NETCORE_ROOT}

EOF

}
