#!/bin/bash
# Reset Production Project (initial active services: Blue)
# This sets all services to the Blue service so that any pipeline run will deploy Green
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Resetting Parks Production Environment in project ${GUID}-parks-prod to Green Services"

# Code to reset the parks production environment to make
# all the green services/routes active.
# This script will be called in the grading pipeline
# if the pipeline is executed without setting
# up the whole infrastructure to guarantee a Blue
# rollout followed by a Green rollout.

curl "http://parksmap-${GUID}-parks-prod.apps.${CLUSTER}/ws/appname/"
curl "http://parksmap-${GUID}-parks-prod.apps.${CLUSTER}/ws/backends/list"

# Scale up mlbparks-green
oc scale dc/mlbparks-green --replicas=1 -n "${GUID}-parks-prod"
oc rollout status dc/mlbparks-green -n "${GUID}-parks-prod"
# Update the route to mlbparks-green
oc patch route/mlbparks -p '{"spec":{"to":{"name":"mlbparks-green"}}}' -n "${GUID}-parks-prod"
# Scale down mlbparks-blue
oc scale dc/mlbparks-blue --replicas=0 -n "${GUID}-parks-prod"

# Scale up nationalparks-green
oc scale dc/nationalparks-green --replicas=1 -n "${GUID}-parks-prod"
oc rollout status dc/nationalparks-green -n "${GUID}-parks-prod"
# Update the route to nationalparks-green
oc patch route/nationalparks -p '{"spec":{"to":{"name":"nationalparks-green"}}}' -n "${GUID}-parks-prod"
# Scale down mlbparks-blue
oc scale dc/nationalparks-blue --replicas=0 -n "${GUID}-parks-prod"

# Scale up parksmap-green
oc scale dc/parksmap-green --replicas=1 -n "${GUID}-parks-prod"
oc rollout status dc/parksmap-green -n "${GUID}-parks-prod"
# Update the route to parksmap-green
oc patch route/parksmap -p '{"spec":{"to":{"name":"parksmap-green"}}}' -n "${GUID}-parks-prod"
# Scale down parksmap-blue
oc scale dc/parksmap-blue --replicas=0 -n "${GUID}-parks-prod"

curl "http://parksmap-${GUID}-parks-prod.apps.${CLUSTER}/ws/appname/"
curl "http://parksmap-${GUID}-parks-prod.apps.${CLUSTER}/ws/backends/list"
