#!/bin/bash
# Reset Production Project (initial active services: Blue)
# This sets all services to the Blue service so that any pipeline run will deploy Green
if [ "$#" -ne 2 ]; then
    echo "Usage:"
    echo "  $0 SERVICE GUID"
    exit 1
fi

SERVICE=$1
GUID=$2

source ./utils.sh
switch_frontend_service_color "${SERVICE}" "${GUID}"