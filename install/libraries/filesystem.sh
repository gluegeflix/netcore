#!/usr/bin/env bash
#
# ==============================================================================
# NetCore Filesystem Library
# ==============================================================================
# Shared filesystem, permissions, file-writing, and backup helpers.
#
# Loaded by:
#   install/libraries/load.sh
#
# ==============================================================================

set -Eeuo pipefail


################################################################################
# Duplicate Load Protection
################################################################################

if [[ "${NETCORE_FILESYSTEM_LIBRARY_LOADED:-false}" == true ]]; then
    return 0
fi

NETCORE_FILESYSTEM_LIBRARY_LOADED=true
export NETCORE_FILESYSTEM_LIBRARY_LOADED


################################################################################
# Directory Creation
################################################################################

create_directory() {

    local DIRECTORY="${1:-}"
    local MODE="${2:-755}"

    if [[ -z "$DIRECTORY" ]]; then
        log_error "create_directory requires a directory path."
        return 1
    fi

    if [[ -d "$DIRECTORY" ]]; then
        log_info "Directory already exists: ${DIRECTORY}"
        return 0
    fi

    if [[ "${DRY_RUN:-false}" == true ]]; then
        log_warn "[DRY RUN] mkdir -p ${DIRECTORY}"
        log_warn "[DRY RUN] chmod ${MODE} ${DIRECTORY}"
        return 0
    fi

    mkdir -p "$DIRECTORY"
    chmod "$MODE" "$DIRECTORY"

    log_success "Created directory: ${DIRECTORY}"

}


################################################################################
# Permission Helper
################################################################################

set_permissions() {

    local PATHNAME="${1:-}"
    local MODE="${2:-}"
    local OWNER="${3:-}"

    if [[ -z "$PATHNAME" || -z "$MODE" ]]; then
        log_error "set_permissions requires a path and mode."
        return 1
    fi

    if [[ ! -e "$PATHNAME" ]]; then
        log_error "Path not found: ${PATHNAME}"
        return 1
    fi

    if [[ "${DRY_RUN:-false}" == true ]]; then
        log_warn "[DRY RUN] chmod ${MODE} ${PATHNAME}"

        if [[ -n "$OWNER" ]]; then
            log_warn "[DRY RUN] chown ${OWNER} ${PATHNAME}"
        fi

        return 0
    fi

    chmod "$MODE" "$PATHNAME"

    if [[ -n "$OWNER" ]]; then
        chown "$OWNER" "$PATHNAME"
    fi

    log_success "Permissions updated: ${PATHNAME}"

}


################################################################################
# Write File
################################################################################

write_file() {

    local DESTINATION="${1:-}"
    local MODE="${2:-644}"
    local OWNER="${3:-}"

    if [[ -z "$DESTINATION" ]]; then
        log_error "write_file requires a destination path."
        return 1
    fi

    local CONTENT
    CONTENT=$(cat)

    if [[ "${DRY_RUN:-false}" == true ]]; then
        log_warn "[DRY RUN] Write file: ${DESTINATION}"
        return 0
    fi

    local PARENT_DIRECTORY
    PARENT_DIRECTORY=$(dirname "$DESTINATION")

    mkdir -p "$PARENT_DIRECTORY"

    printf '%s\n' "$CONTENT" > "$DESTINATION"

    chmod "$MODE" "$DESTINATION"

    if [[ -n "$OWNER" ]]; then
        chown "$OWNER" "$DESTINATION"
    fi

    log_success "Wrote file: ${DESTINATION}"

}


################################################################################
# Append File
################################################################################

append_file() {

    local DESTINATION="${1:-}"
    local MODE="${2:-644}"
    local OWNER="${3:-}"

    if [[ -z "$DESTINATION" ]]; then
        log_error "append_file requires a destination path."
        return 1
    fi

    local CONTENT
    CONTENT=$(cat)

    if [[ "${DRY_RUN:-false}" == true ]]; then
        log_warn "[DRY RUN] Append to file: ${DESTINATION}"
        return 0
    fi

    local PARENT_DIRECTORY
    PARENT_DIRECTORY=$(dirname "$DESTINATION")

    mkdir -p "$PARENT_DIRECTORY"

    printf '%s\n' "$CONTENT" >> "$DESTINATION"

    chmod "$MODE" "$DESTINATION"

    if [[ -n "$OWNER" ]]; then
        chown "$OWNER" "$DESTINATION"
    fi

    log_success "Updated file: ${DESTINATION}"

}


################################################################################
# File Backup
################################################################################

backup_file() {

    local FILE="${1:-}"
    local BACKUP_ROOT="${2:-}"

    if [[ -z "$FILE" ]]; then
        log_error "backup_file requires a file path."
        return 1
    fi

    if [[ ! -e "$FILE" ]]; then
        log_warn "File does not exist, skipping backup: ${FILE}"
        return 0
    fi

    local TIMESTAMP
    TIMESTAMP=$(date "+%Y%m%d-%H%M%S")

    local BACKUP_PATH

    if [[ -n "$BACKUP_ROOT" ]]; then
        create_directory "$BACKUP_ROOT"
        BACKUP_PATH="${BACKUP_ROOT}/$(basename "$FILE").netcore-backup-${TIMESTAMP}"
    else
        BACKUP_PATH="${FILE}.netcore-backup-${TIMESTAMP}"
    fi

    if [[ "${DRY_RUN:-false}" == true ]]; then
        log_warn "[DRY RUN] cp -a ${FILE} ${BACKUP_PATH}"
        return 0
    fi

    cp -a "$FILE" "$BACKUP_PATH"

    log_success "Backup created: ${BACKUP_PATH}"
    printf '%s\n' "$BACKUP_PATH"

}


################################################################################
# Directory Backup
################################################################################

backup_directory() {

    local DIRECTORY="${1:-}"
    local BACKUP_ROOT="${2:-}"

    if [[ -z "$DIRECTORY" ]]; then
        log_error "backup_directory requires a directory path."
        return 1
    fi

    if [[ ! -d "$DIRECTORY" ]]; then
        log_warn "Directory does not exist, skipping backup: ${DIRECTORY}"
        return 0
    fi

    local TIMESTAMP
    TIMESTAMP=$(date "+%Y%m%d-%H%M%S")

    if [[ -z "$BACKUP_ROOT" ]]; then
        BACKUP_ROOT="$(dirname "$DIRECTORY")"
    fi

    create_directory "$BACKUP_ROOT"

    local DIRECTORY_NAME
    DIRECTORY_NAME=$(basename "$DIRECTORY")

    local ARCHIVE
    ARCHIVE="${BACKUP_ROOT}/${DIRECTORY_NAME}.netcore-backup-${TIMESTAMP}.tar.gz"

    if [[ "${DRY_RUN:-false}" == true ]]; then
        log_warn "[DRY RUN] tar -czpf ${ARCHIVE} -C $(dirname "$DIRECTORY") ${DIRECTORY_NAME}"
        return 0
    fi

    tar \
        --create \
        --gzip \
        --preserve-permissions \
        --file "$ARCHIVE" \
        --directory "$(dirname "$DIRECTORY")" \
        "$DIRECTORY_NAME"

    log_success "Directory backup created: ${ARCHIVE}"
    printf '%s\n' "$ARCHIVE"

}


################################################################################
# Restore Backup
################################################################################

restore_backup() {

    local BACKUP="${1:-}"
    local DESTINATION="${2:-}"

    if [[ -z "$BACKUP" || -z "$DESTINATION" ]]; then
        log_error "restore_backup requires a backup and destination."
        return 1
    fi

    if [[ ! -e "$BACKUP" ]]; then
        log_error "Backup not found: ${BACKUP}"
        return 1
    fi

    if [[ "${DRY_RUN:-false}" == true ]]; then
        log_warn "[DRY RUN] Restore ${BACKUP} to ${DESTINATION}"
        return 0
    fi

    if [[ -e "$DESTINATION" ]]; then
        if [[ -d "$DESTINATION" ]]; then
            backup_directory "$DESTINATION"
        else
            backup_file "$DESTINATION"
        fi
    fi

    if [[ "$BACKUP" == *.tar.gz || "$BACKUP" == *.tgz ]]; then

        local DESTINATION_PARENT
        DESTINATION_PARENT=$(dirname "$DESTINATION")

        mkdir -p "$DESTINATION_PARENT"

        tar \
            --extract \
            --gzip \
            --preserve-permissions \
            --file "$BACKUP" \
            --directory "$DESTINATION_PARENT"

    else

        cp -a "$BACKUP" "$DESTINATION"

    fi

    log_success "Backup restored to: ${DESTINATION}"

}
