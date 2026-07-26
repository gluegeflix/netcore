#!/usr/bin/env bash
#
# ==============================================================================
# NetCore Common Library
# ==============================================================================
# Shared helper functions used by all NetCore installer modules.
#
# ==============================================================================

set -Eeuo pipefail


################################################################################
# Version
################################################################################

readonly NETCORE_VERSION="0.1.0"


################################################################################
# Determine NetCore Root
################################################################################

if [[ -z "${NETCORE_ROOT:-}" ]]; then

    NETCORE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

fi

export NETCORE_ROOT


################################################################################
# Logging Variables
################################################################################

LOG_DIR=""
LOG_FILE=""


################################################################################
# Options
################################################################################

VERBOSE=false
DRY_RUN=false
AUTO_YES=false
UNATTENDED=false

################################################################################
# Colors
################################################################################

RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
CYAN="\033[0;36m"
NC="\033[0m"


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

        echo "${TIME} [${LEVEL}] ${MESSAGE}" >> "${LOG_FILE}" 2>/dev/null || true

    fi

}


log_info() {

    write_log "INFO" "$*"

    echo -e "${BLUE}[INFO]${NC} $*"

}


log_success() {

    write_log "OK" "$*"

    echo -e "${GREEN}[ OK ]${NC} $*"

}


log_warn() {

    write_log "WARN" "$*"

    echo -e "${YELLOW}[WARN]${NC} $*"

}


log_error() {

    write_log "FAIL" "$*"

    echo -e "${RED}[FAIL]${NC} $*" >&2

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


################################################################################
# Argument Handling
################################################################################

parse_args() {


    while [[ $# -gt 0 ]]; do


        case "$1" in


            --verbose)

                VERBOSE=true

                ;;


            --dry-run)

                DRY_RUN=true

                ;;

            --yes|-y)

                AUTO_YES=true

               ;;
            --unattended)

                UNATTENDED=true
                AUTO_YES=true
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


        log_error "This installer must be run as root."

        exit 1


    fi

}


################################################################################
# OS Check
################################################################################

check_os() {


    source /etc/os-release


    if [[ "${ID}" != "ubuntu" ]]; then

        log_error "Unsupported operating system: ${ID}"

        exit 1

    fi


    log_success "Ubuntu detected."

}


################################################################################
# Internet Check
################################################################################

check_internet() {


    log_info "Checking internet connectivity..."


    if ping -c 2 1.1.1.1 >/dev/null 2>&1; then

        log_success "Internet connection OK."

    else

        log_error "Internet connection failed."

        exit 1

    fi

}


################################################################################
# Command Helpers
################################################################################

command_exists() {

    command -v "$1" >/dev/null 2>&1

}



run_command() {


    local DESCRIPTION="$1"

    shift


    log_info "$DESCRIPTION"


    if [[ "$DRY_RUN" == true ]]; then

        log_warn "[DRY RUN] $*"

        return 0

    fi


    if [[ -n "${LOG_FILE:-}" ]]; then


        "$@" 2>&1 | tee -a "$LOG_FILE"


    else


        "$@"


    fi


    local RESULT=${PIPESTATUS[0]}


    if [[ $RESULT -ne 0 ]]; then


        log_error "Command failed: $*"

        return "$RESULT"


    fi


    log_success "$DESCRIPTION"

}



################################################################################
# Package Helpers
################################################################################

install_package() {


    local PACKAGE="$1"


    if dpkg -s "$PACKAGE" >/dev/null 2>&1; then


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

service_exists() {

    local SERVICE="$1"


    if systemctl list-unit-files --type=service \
        | grep -q "^${SERVICE}\.service"; then

        return 0

    fi


    if systemctl status "$SERVICE" >/dev/null 2>&1; then

        return 0

    fi


    return 1

}

is_service_active() {

    local SERVICE="$1"


    if systemctl is-active --quiet "$SERVICE"; then

        return 0

    else

        return 1

    fi

}

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
# Directory Helpers
################################################################################

create_directory() {


    local DIR="$1"


    if [[ -z "$DIR" ]]; then

        log_error "create_directory requires a path."

        return 1

    fi


    if [[ ! -d "$DIR" ]]; then


        mkdir -p "$DIR"

        log_success "Created directory: $DIR"


    else


        log_info "Directory already exists: $DIR"


    fi

}



################################################################################
# Backup Helpers
################################################################################

backup_file() {


    local FILE="$1"


    if [[ -z "$FILE" ]]; then


        log_error "backup_file requires a file path."

        return 1


    fi



    if [[ ! -e "$FILE" ]]; then


        log_warn "File does not exist, skipping backup: $FILE"

        return 0


    fi



    local BACKUP_FILE


    BACKUP_FILE="${FILE}.netcore-backup-$(date +%Y%m%d-%H%M%S)"



    cp -a "$FILE" "$BACKUP_FILE"



    log_success "Backup created"

    log_info "$BACKUP_FILE"


}
################################################################################
# Directory Backup Helper
################################################################################

backup_directory() {

    local DIR="$1"

    

}
################################################################################
# Restore Backup Helper
################################################################################

restore_backup() {

    local BACKUP="$1"

    local DESTINATION="$2"


    if [[ -z "$BACKUP" || -z "$DESTINATION" ]]; then

        log_error "restore_backup requires backup file and destination."

        return 1

    fi


    if [[ ! -e "$BACKUP" ]]; then

        log_error "Backup file not found: $BACKUP"

        return 1

    fi


    if [[ -e "$DESTINATION" ]]; then

        backup_file "$DESTINATION"

    fi


    cp -a "$BACKUP" "$DESTINATION"


    log_success "Backup restored"

    log_info "Source: $BACKUP"

    log_info "Destination: $DESTINATION"

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
# Confirmation Helper
################################################################################

confirm_action() {

    local PROMPT="${1:-Continue?}"

    #
    # Never prompt in unattended mode
    #
    if [[ "$UNATTENDED" == true ]]; then

        log_info "UNATTENDED mode: automatically confirmed."

        return 0

    fi

    #
    # Skip prompts when --yes is used
    #
    if [[ "$AUTO_YES" == true ]]; then

        log_info "AUTO_YES enabled."

        return 0

    fi

    while true; do

        read -rp "${PROMPT} [y/N]: " RESPONSE

        case "${RESPONSE,,}" in

            y|yes)

                return 0
                ;;

            n|no|"")

                return 1
                ;;

            *)

                echo "Please answer yes or no."
                ;;

        esac

    done

}
################################################################################
# Require User Input
################################################################################

require_input() {

    local VALUE="$1"
    local MESSAGE="$2"

    if [[ -n "$VALUE" ]]; then
        return 0
    fi

    if [[ "$UNATTENDED" == true ]]; then

        log_error "$MESSAGE"

        return 1

    fi

    return 0

}
################################################################################
# Cleanup
################################################################################

cleanup() {


    apt-get autoremove -y

    apt-get autoclean -y


}



################################################################################
# Error Handler
################################################################################

on_error() {


    local EXIT_CODE=$?


    log_error "Installer failed with code ${EXIT_CODE}"


    exit "$EXIT_CODE"


}


trap on_error ERR
