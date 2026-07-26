#!/usr/bin/env bash

set -Eeuo pipefail

export NETCORE_ROOT="$(pwd)"

source install/modules/00-common.sh

init_logging


if service_exists ssh; then

    log_success "SSH service exists"

else

    log_warn "SSH service not found"

fi


if service_exists fake-service; then

    log_success "Fake service exists"

else

    log_warn "Fake service not found"

fi
