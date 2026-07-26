#!/usr/bin/env bash

set -Eeuo pipefail

export NETCORE_ROOT="$(pwd)"

source install/modules/00-common.sh

parse_args "$@"

init_logging

EMPTY_VALUE=""

require_input "$EMPTY_VALUE" \
    "A required configuration value is missing."

log_success "Configuration validated."
