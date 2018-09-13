#!/bin/bash
source "${BIN_PATH:-./Infrastructure/bin}"/utils.sh

# Setup Development Project
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
CLUSTER="na39.openshift.opentlc.com"

echo "Setting up Parks Development Environment in project ${GUID}-parks-dev"

# Code to set up the parks development project.

# To be Implemented by Student
oc_project "$GUID" 'parks-dev'

echo '------ Setting up the DEV project ------'
oc policy add-role-to-user edit "system:serviceaccount:${GUID}-jenkins:jenkins" \
  -n "${GUID}-parks-dev"

echo '------ Setting up the ephemeral MongoDB ------'
source "${BIN_PATH:-./Infrastructure/bin}"/configs/mongodb_dev.sh
# https://docs.openshift.com/container-platform/3.9/using_images/db_images/mongodb.html
oc new-app \
    -p MONGODB_USER="$MONGODB_USERNAME" \
    -p MONGODB_PASSWORD="$MONGODB_PASSWORD" \
    -p MONGODB_DATABASE="$MONGODB_DATABASE" \
    -p MONGODB_ADMIN_PASSWORD="$MONGODB_ADMIN_PASSWORD" \
    --name="$MONGODB_SERVICE_NAME" \
    mongodb-ephemeral \
    -n "${GUID}-parks-dev"

oc create configmap mongodb-config \
    --from-literal DB_HOST="$MONGODB_HOST" \
    --from-literal DB_PORT="$MONGODB_PORT" \
    --from-literal DB_USERNAME="$MONGODB_USERNAME" \
    --from-literal DB_PASSWORD="$MONGODB_PASSWORD" \
    --from-literal DB_NAME="$MONGODB_DATABASE" \
    --from-literal DB_DATABASE="$MONGODB_DATABASE" \
    -n "${GUID}-parks-dev"
##    --from-literal DB_REPLICASET="$MONGODB_REPLICASET"

echo '------ Setting up the MLB Parks backend Application ------'
## https://github.com/wkulhanek/advdev_homework_template/tree/master/MLBParks
oc create configmap mlbparks-config \
  --from-literal="APPNAME=MLB Parks (Dev)" \
  -n "${GUID}-parks-dev"

oc new-build --binary=true --name="mlbparks" jboss-eap70-openshift:1.7 -n "${GUID}-parks-dev"
oc new-app "${GUID}-parks-dev/mlbparks:latest" --name=mlbparks \
  -l type=parksmap-backend \
  --allow-missing-imagestream-tags=true --allow-missing-images=true \
  -n "${GUID}-parks-dev"

oc set env dc/mlbparks --from configmap/mlbparks-config -n "${GUID}-parks-dev"
oc set env dc/mlbparks --from configmap/mongodb-config -n "${GUID}-parks-dev"

oc set triggers dc/mlbparks --remove-all -n "${GUID}-parks-dev"
oc expose dc mlbparks --port 8080 -n "${GUID}-parks-dev"
oc expose svc mlbparks -n "${GUID}-parks-dev"

oc set probe dc/mlbparks --readiness --get-url=http://:8080/ws/healthz/ \
  --initial-delay-seconds=30 --period-seconds=10 --timeout-seconds=5 \
   -n "${GUID}-parks-dev"
oc set probe dc/mlbparks --liveness --get-url=http://:8080/ws/healthz/ \
  --initial-delay-seconds=45 --period-seconds=10 --timeout-seconds=5 \
   -n "${GUID}-parks-dev"

echo '------ Setting up the Nationalparks backend Application ------'
## https://github.com/wkulhanek/advdev_homework_template/tree/master/Nationalparks
oc create configmap nationalparks-config \
  --from-literal="APPNAME=National Parks (Dev)" \
   -n "${GUID}-parks-dev"

oc new-build --binary=true --name="nationalparks" redhat-openjdk18-openshift:1.2 \
   -n "${GUID}-parks-dev"
oc new-app "${GUID}-parks-dev/nationalparks:latest" --name=nationalparks \
  -l type=parksmap-backend \
  --allow-missing-imagestream-tags=true --allow-missing-images=true \
   -n "${GUID}-parks-dev"

oc set env dc/nationalparks --from configmap/nationalparks-config -n "${GUID}-parks-dev"
oc set env dc/nationalparks --from configmap/mongodb-config -n "${GUID}-parks-dev"

oc set triggers dc/nationalparks --remove-all -n "${GUID}-parks-dev"
oc expose dc nationalparks --port 8080 -n "${GUID}-parks-dev"
oc expose svc nationalparks -n "${GUID}-parks-dev"

oc set probe dc/nationalparks --readiness --get-url=http://:8080/ws/healthz/ \
  --initial-delay-seconds=30 --period-seconds=10 --timeout-seconds=5 \
   -n "${GUID}-parks-dev"
oc set probe dc/nationalparks --liveness --get-url=http://:8080/ws/healthz/ \
  --initial-delay-seconds=45 --period-seconds=10 --timeout-seconds=5 \
   -n "${GUID}-parks-dev"

echo '------ Setting up the ParksMap frontend Application ------'
## https://github.com/wkulhanek/advdev_homework_template/tree/master/ParksMap
oc new-build --binary=true --name="parksmap" redhat-openjdk18-openshift:1.2 -n "${GUID}-parks-dev"
oc new-app "${GUID}-parks-dev/parksmap:latest" --name=parksmap \
  --allow-missing-imagestream-tags=true --allow-missing-images=true \
   -n "${GUID}-parks-dev"

oc set env dc/parksmap -e "APPNAME=ParksMap (Dev)" -n "${GUID}-parks-dev"

oc policy add-role-to-user view --serviceaccount=default -n "${GUID}-parks-dev"

oc set triggers dc/parksmap --remove-all -n "${GUID}-parks-dev"
oc expose dc parksmap --port 8080 -n "${GUID}-parks-dev"
oc expose svc parksmap -n "${GUID}-parks-dev"

oc set probe dc/parksmap --readiness --get-url=http://:8080/ws/healthz/ \
  --initial-delay-seconds=30 --period-seconds=10 --timeout-seconds=5 \
   -n "${GUID}-parks-dev"
oc set probe dc/parksmap --liveness --get-url=http://:8080/ws/healthz/ \
  --initial-delay-seconds=45 --period-seconds=10 --timeout-seconds=5 \
   -n "${GUID}-parks-dev"

echo '------ Start dev-pipeline ------'
#oc_project "$GUID" 'jenkins'

#oc start-build mlbparks-pipeline -n "${GUID}-jenkins"