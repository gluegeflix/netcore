#!/usr/bin/env bash


source install/modules/00-common.sh

source install/modules/00-config.sh


parse_args "$@"


init_logging


print_banner


echo "NetCore Root:"
echo "$NETCORE_ROOT"


load_config


show_config
