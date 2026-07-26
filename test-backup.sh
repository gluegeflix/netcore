#!/usr/bin/env bash

set -Eeuo pipefail

export NETCORE_ROOT="$(pwd)"

source install/modules/00-common.sh

init_logging


echo "test configuration" > /tmp/netcore-test.conf


backup_file /tmp/netcore-test.conf
