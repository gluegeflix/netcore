#!/usr/bin/env bash

set -Eeuo pipefail


export NETCORE_ROOT="$(pwd)"


source install/modules/00-common.sh


init_logging


mkdir -p /tmp/netcore-test-directory/config


echo "test configuration" > /tmp/netcore-test-directory/config/test.conf


backup_directory /tmp/netcore-test-directory
