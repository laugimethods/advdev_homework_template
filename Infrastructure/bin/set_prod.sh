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
echo ""
curl "http://parksmap-${GUID}-parks-prod.apps.${CLUSTER}/ws/backends/list"
echo ""

# Scale up mlbparks-blue
oc scale dc/mlbparks-blue --replicas=1 -n "${GUID}-parks-prod"
oc rollout latest dc/mlbparks-blue -n "${GUID}-parks-prod"
oc rollout status dc/mlbparks-blue -n "${GUID}-parks-prod"
curl "http://mlbparks-blue-${GUID}-parks-prod.apps.${CLUSTER}/ws/info/"
# Update the route to mlbparks-blue
oc patch route/mlbparks -p '{"spec":{"to":{"name":"mlbparks-blue"}}}' -n "${GUID}-parks-prod"
# Scale down mlbparks-green
oc scale dc/mlbparks-green --replicas=0 -n "${GUID}-parks-prod"

# Scale up nationalparks-blue
oc scale dc/nationalparks-blue --replicas=1 -n "${GUID}-parks-prod"
oc rollout latest dc/nationalparks-blue -n "${GUID}-parks-prod"
oc rollout status dc/nationalparks-blue -n "${GUID}-parks-prod"
curl "http://nationalparks-blue-${GUID}-parks-prod.apps.${CLUSTER}/ws/info/"
# Update the route to nationalparks-blue
oc patch route/nationalparks -p '{"spec":{"to":{"name":"nationalparks-blue"}}}' -n "${GUID}-parks-prod"
# Scale down nationalparks-green
oc scale dc/nationalparks-green --replicas=0 -n "${GUID}-parks-prod"

# Scale up parksmap-blue
oc scale dc/parksmap-blue --replicas=1 -n "${GUID}-parks-prod"
oc rollout latest dc/parksmap-blue -n "${GUID}-parks-prod"
oc rollout status dc/parksmap-blue -n "${GUID}-parks-prod"
curl "http://parksmap-blue-${GUID}-parks-prod.apps.${CLUSTER}/ws/appname/"
echo ""
curl "http://parksmap-blue-${GUID}-parks-prod.apps.${CLUSTER}/ws/backends/list"
echo ""
# Update the route to parksmap-blue
oc patch service/parksmap \
  -p '{"metadata":{"labels":{"app":"parksmap-blue", "template":"parksmap-blue"}},
       "spec":{"selector":{"app":"parksmap-blue", "deploymentconfig":"parksmap-blue"}}}' \
  -n "${GUID}-parks-prod"
# Scale down parksmap-green
oc scale dc/parksmap-green --replicas=0 -n "${GUID}-parks-prod"

curl "http://parksmap-${GUID}-parks-prod.apps.${CLUSTER}/ws/appname/"
echo ""
curl "http://parksmap-${GUID}-parks-prod.apps.${CLUSTER}/ws/backends/list"
echo ""
