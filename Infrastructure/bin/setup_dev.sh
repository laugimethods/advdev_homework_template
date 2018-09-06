#!/bin/bash
source ./utils.sh

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
oc policy add-role-to-user edit "system:serviceaccount:${GUID}-jenkins:jenkins"

echo '------ Setting up the ephemeral MongoDB ------'
source ./configs/mongodb_dev.sh
# https://docs.openshift.com/container-platform/3.9/using_images/db_images/mongodb.html
oc new-app \
    -p MONGODB_USER="$MONGODB_USERNAME" \
    -p MONGODB_PASSWORD="$MONGODB_PASSWORD" \
    -p MONGODB_DATABASE="$MONGODB_DATABASE" \
    -p MONGODB_ADMIN_PASSWORD="$MONGODB_ADMIN_PASSWORD" \
    --name="$MONGODB_SERVICE_NAME" \
    mongodb-ephemeral

oc create configmap mongodb-config \
    --from-literal DB_HOST="$MONGODB_HOST" \
    --from-literal DB_PORT="$MONGODB_PORT" \
    --from-literal DB_USERNAME="$MONGODB_USERNAME" \
    --from-literal DB_PASSWORD="$MONGODB_PASSWORD" \
    --from-literal DB_NAME="$MONGODB_DATABASE" \
    --from-literal DB_DATABASE="$MONGODB_DATABASE"
##    --from-literal DB_REPLICASET="$MONGODB_REPLICASET"

echo '------ Setting up the MLB Parks backend Application ------'
## https://github.com/wkulhanek/advdev_homework_template/tree/master/MLBParks
oc create configmap mlbparks-config \
  --from-literal="APPNAME=MLB Parks (Dev)"

oc new-build --binary=true --name="mlbparks" jboss-eap70-openshift:1.7
oc new-app "${GUID}-parks-dev/mlbparks:latest" --name=mlbparks \
  -l type=parksmap-backend \
  --allow-missing-imagestream-tags=true --allow-missing-images=true

oc set env dc/mlbparks --from configmap/mlbparks-config
oc set env dc/mlbparks --from configmap/mongodb-config

oc set triggers dc/mlbparks --remove-all
oc expose dc mlbparks --port 8080
oc expose svc mlbparks

echo '------ Setting up the Nationalparks backend Application ------'
## https://github.com/wkulhanek/advdev_homework_template/tree/master/Nationalparks
oc create configmap nationalparks-config \
  --from-literal="APPNAME=National Parks (Dev)"

oc new-build --binary=true --name="nationalparks" redhat-openjdk18-openshift:1.2
oc new-app "${GUID}-parks-dev/nationalparks:latest" --name=nationalparks \
  -l type=parksmap-backend \
  --allow-missing-imagestream-tags=true --allow-missing-images=true

oc set env dc/nationalparks --from configmap/nationalparks-config
oc set env dc/nationalparks --from configmap/mongodb-config

oc set triggers dc/nationalparks --remove-all
oc expose dc nationalparks --port 8080
oc expose svc nationalparks


echo '------ Setting up the ParksMap frontend Application ------'
## https://github.com/wkulhanek/advdev_homework_template/tree/master/ParksMap
oc new-build --binary=true --name="parksmap" redhat-openjdk18-openshift:1.2
oc new-app "${GUID}-parks-dev/parksmap:latest" --name=parksmap \
  --allow-missing-imagestream-tags=true --allow-missing-images=true

oc set env dc/parksmap -e "APPNAME=ParksMap (Dev)"

oc policy add-role-to-user view --serviceaccount=default

oc set triggers dc/parksmap --remove-all
oc expose dc parksmap --port 8080
oc expose svc parksmap

echo '------ Start dev-pipeline ------'
#oc_project "$GUID" 'jenkins'

#oc start-build mlbparks-pipeline -n "${GUID}-jenkins"