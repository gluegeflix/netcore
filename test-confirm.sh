#!/usr/bin/env bash

set -Eeuo pipefail

export NETCORE_ROOT="$(pwd)"

source install/modules/00-common.sh

parse_args "$@"

init_logging

if confirm_action "Do you want to continue?"; then

    log_success "User confirmed."

else

    log_warn "User declined."

fi
