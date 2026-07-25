#!/usr/bin/env bash
#
# ==============================================================================
# NetCore Common Library
# ==============================================================================
# Shared helper functions used by every NetCore installer module.
# ==============================================================================

set -Eeuo pipefail


################################################################################
# Variables
################################################################################

################################################################################
# Variables
################################################################################

readonly NETCORE_VERSION="0.1.0"

#
# Determine NetCore project root directory
#
NETCORE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

export NETCORE_ROOT


#
# Logging
#
LOG_DIR="/var/log/netcore"
LOG_FILE="${LOG_DIR}/install.log"


#
# Runtime options
#
VERBOSE=false
DRY_RUN=false


################################################################################
# Colors
################################################################################

RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m"


################################################################################
# Logging Initialization
################################################################################

init_logging() {

    if [[ $EUID -eq 0 ]]; then

        mkdir -p "$LOG_DIR"
        touch "$LOG_FILE"
        chmod 644 "$LOG_FILE"

    else

        LOG_DIR="./logs"
        LOG_FILE="${LOG_DIR}/install.log"

        mkdir -p "$LOG_DIR"

        touch "$LOG_FILE"

    fi

}


################################################################################
# Logging
################################################################################

log() {

    local LEVEL="$1"
    shift

    local MESSAGE="$*"

    local TIME

    TIME=$(date +"%Y-%m-%d %H:%M:%S")

    echo "${TIME} [${LEVEL}] ${MESSAGE}" >> "$LOG_FILE"


    case "$LEVEL" in

        INFO)
            echo -e "${BLUE}[INFO]${NC} ${MESSAGE}"
            ;;

        OK)
            echo -e "${GREEN}[ OK ]${NC} ${MESSAGE}"
            ;;

        WARN)
            echo -e "${YELLOW}[WARN]${NC} ${MESSAGE}"
            ;;

        ERROR)
            echo -e "${RED}[FAIL]${NC} ${MESSAGE}"
            ;;

    esac
}


log_info() {
    log INFO "$@"
}


log_success() {
    log OK "$@"
}


log_warn() {
    log WARN "$@"
}


log_error() {
    log ERROR "$@"
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

EOF

}


################################################################################
# Argument Parser
################################################################################

parse_args() {

    while [[ $# -gt 0 ]]
    do

        case "$1" in

            --verbose)
                VERBOSE=true
                ;;

            --dry-run)
                DRY_RUN=true
                ;;

            --help)
                echo "Usage:"
                echo "  --verbose"
                echo "  --dry-run"
                exit 0
                ;;

            *)
                log_error "Unknown option: $1"
                exit 1
                ;;

        esac

        shift

    done
}


################################################################################
# Root Check
################################################################################

require_root() {

    if [[ $EUID -ne 0 ]]; then

        log_error "Run this installer as root."

        exit 1

    fi
}


################################################################################
# OS Check
################################################################################

check_os() {

    source /etc/os-release

    if [[ "$ID" != "ubuntu" ]]; then

        log_error "Unsupported OS: $ID"

        exit 1

    fi


    log_success "Ubuntu detected."
}


################################################################################
# Internet Check
################################################################################

check_internet() {

    log_info "Checking internet..."

    if ping -c 2 1.1.1.1 >/dev/null 2>&1
    then

        log_success "Internet available."

    else

        log_error "No internet connection."

        exit 1

    fi
}


################################################################################
# Command Check
################################################################################

command_exists() {

    command -v "$1" >/dev/null 2>&1

}


################################################################################
# Command Runner
################################################################################

run_command() {

    local DESCRIPTION="$1"

    shift


    log_info "$DESCRIPTION"


    if $DRY_RUN
    then

        log_warn "[DRY RUN] $*"

        return 0

    fi


    if $VERBOSE
    then

        "$@" 2>&1 | tee -a "$LOG_FILE"

    else

        "$@" >> "$LOG_FILE" 2>&1

    fi


    local RESULT=$?


    if [[ $RESULT -eq 0 ]]
    then

        log_success "$DESCRIPTION"

    else

        log_error "$DESCRIPTION failed"

        exit "$RESULT"

    fi

}


################################################################################
# Package Helper
################################################################################

install_package() {

    local PACKAGE="$1"


    if dpkg -s "$PACKAGE" >/dev/null 2>&1
    then

        log_success "$PACKAGE already installed."

    else

        run_command \
        "Installing $PACKAGE" \
        apt-get install -y "$PACKAGE"

    fi

}


################################################################################
# Service Helpers
################################################################################

enable_service() {

    local SERVICE="$1"

    run_command \
    "Enable $SERVICE" \
    systemctl enable --now "$SERVICE"

}


restart_service() {

    local SERVICE="$1"

    run_command \
    "Restart $SERVICE" \
    systemctl restart "$SERVICE"

}


################################################################################
# Step Display
################################################################################

step() {

echo

echo "------------------------------------------------------"

echo "$1"

echo "------------------------------------------------------"

}


################################################################################
# Cleanup
################################################################################

cleanup() {

    run_command \
    "Cleaning packages" \
    apt-get autoremove -y

}


################################################################################
# Error Handler
################################################################################

on_error() {

    local EXIT_CODE=$?

    log_error "Installer failed with code $EXIT_CODE"

    exit "$EXIT_CODE"

}


trap on_error ERR
