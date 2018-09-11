#!/bin/bash
# Reset Production Project (initial active services: Blue)
# This sets all services to the Blue service so that any pipeline run will deploy Green
if [ "$#" -ne 4 ]; then
    echo "Usage:"
    echo "  $0 SERVICE CURRENT TARGET GUID"
    exit 1
fi

SERVICE=$1
CURRENT=$2
TARGET=$3
GUID=$4

source ./utils.sh
switch_service_color "${SERVICE}" "${CURRENT}" "${TARGET}" "${GUID}"