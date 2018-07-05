#!/bin/bash

oc_project () {
  GUID=$1
  PROJECT=$2
  while : ; do
    echo "Try to connect to the ${GUID}-${PROJECT} Project..."
    oc project ${GUID}-${PROJECT}
    [[ "$?" == "1" ]] || break
    echo "Not Ready Yet. Sleeping 5 seconds."
    sleep 5
  done
}