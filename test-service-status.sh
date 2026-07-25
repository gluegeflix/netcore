#!/usr/bin/env bash

set -Eeuo pipefail


export NETCORE_ROOT="$(pwd)"


source install/modules/00-common.sh


init_logging


SERVICE="fail2ban"


if service_exists "$SERVICE"; then

    log_success "$SERVICE is installed"

else

    log_warn "$SERVICE is not installed"

fi



if is_service_active "$SERVICE"; then

    log_success "$SERVICE is running"

else

    log_warn "$SERVICE is stopped"

fi
