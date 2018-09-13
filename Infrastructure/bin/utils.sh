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

switch_backend_service_color() {
  SERVICE=$1
  GUID=$2

  switch_service_color $SERVICE $GUID 'wait' $(curl "http://${SERVICE}-${GUID}-parks-prod.apps.${CLUSTER}/ws/info/")
}

switch_frontend_service_color() {
  SERVICE=$1
  GUID=$2

  switch_service_color $SERVICE $GUID 'wait' $(curl "http://${SERVICE}-${GUID}-parks-prod.apps.${CLUSTER}/ws/appname/")
}

switch_service_color() {
  SERVICE=$1
  GUID=$2
  WAIT=$3
  COLOR_RESPONSE=$4

  echo "$1 / $2 / $3 / $4"

  if [[ $COLOR_RESPONSE = *"Blue"* ]]; then
    CURRENT='blue'
    TARGET='green'
  else
    CURRENT='green'
    TARGET='blue'
  fi

  echo ""
  echo "---------------------------------------------------------------------------------------------------------------------"
  echo "Setting ${SERVICE} Service in Parks Production Environment in project ${GUID}-parks-prod from ${CURRENT} to ${TARGET}"
  echo ""

  # Scale up TARGET SERVICE
  oc scale dc/${SERVICE}-${TARGET} --replicas=1 -n "${GUID}-parks-prod"
  oc rollout latest dc/${SERVICE}-${TARGET} -n "${GUID}-parks-prod"

  if [[ $WAIT == "wait" ]]; then ## Service was already alive, so wait for the new version
    oc rollout status dc/${SERVICE}-${TARGET} -n "${GUID}-parks-prod"
  fi

  # Update the route to ${SERVICE}-${TARGET}
  oc patch service/${SERVICE} \
    -p "{\"metadata\":{\"labels\":{\"app\":\"${SERVICE}-${TARGET}\", \"template\":\"${SERVICE}-${TARGET}\"}}, \
    \"spec\":{\"selector\":{\"app\":\"${SERVICE}-${TARGET}\", \"deploymentconfig\":\"${SERVICE}-${TARGET}\"}}}" \
    -n "${GUID}-parks-prod"
  # Scale down ${SERVICE}-${CURRENT}
  oc scale dc/${SERVICE}-${CURRENT} --replicas=0 -n "${GUID}-parks-prod"
}

switch_all_service_color() {
  GUID=$1
  ORIGIN=$2
  readonly ORIGIN

  curl "http://parksmap-${GUID}-parks-prod.apps.${CLUSTER}/ws/appname/"
  echo ""
  curl "http://parksmap-${GUID}-parks-prod.apps.${CLUSTER}/ws/backends/list"
  echo ""

  switch_service_color 'mlbparks' "${GUID}" 'pass' "${ORIGIN}"
  curl "http://mlbparks-${TARGET}-${GUID}-parks-prod.apps.${CLUSTER}/ws/info/"

  switch_service_color 'nationalparks' "${GUID}" 'pass' "${ORIGIN}"
  curl "http://nationalparks-${TARGET}-${GUID}-parks-prod.apps.${CLUSTER}/ws/info/"

  switch_service_color 'parksmap' "${GUID}" 'pass' "${ORIGIN}"

  curl "http://parksmap-${GUID}-parks-prod.apps.${CLUSTER}/ws/appname/"
  echo ""
  curl "http://parksmap-${GUID}-parks-prod.apps.${CLUSTER}/ws/backends/list"
  echo ""
}
