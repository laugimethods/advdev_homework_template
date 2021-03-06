#!/bin/bash
# Reset Production Project (initial active services: Blue)
# This sets all services to the Blue service so that any pipeline run will deploy Green
if [ "$#" -ne 3 ]; then
    echo "Usage:"
    echo "  $0 SERVICE GUID CLUSTER"
    exit 1
fi

SERVICE=$1
GUID=$2
CLUSTER=$3

BASEDIR=$(dirname "$0")
source "${BASEDIR}/utils.sh"
switch_backend_service_color "${SERVICE}" "${GUID}" "${CLUSTER}"