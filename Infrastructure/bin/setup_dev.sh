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
    --name="$MONGODB_NAME" \
    mongodb-ephemeral

oc create configmap mongodb-config \
    --from-literal DB_HOST="$MONGODB_HOST" \
    --from-literal DB_PORT="$MONGODB_PORT" \
    --from-literal DB_NAME="$MONGODB_NAME" \
    --from-literal DB_DATABASE="$MONGODB_DATABASE" \
    --from-literal DB_USERNAME="$MONGODB_USERNAME" \
    --from-literal DB_PASSWORD="$MONGODB_PASSWORD" \
    --from-literal DB_REPLICASET="$MONGODB_REPLICASET"

echo '------ Setting up the MLB Parks Application ------'
oc new-build --binary=true --name="mlbparks" jboss-eap70-openshift:1.7

oc create configmap mlbparks-config \
  --from-literal="APPNAME=MLB Parks (Dev)"
oc new-app "${GUID}-parks-dev/mlbparks:0.0-0" --name=mlbparks --allow-missing-imagestream-tags=true
oc set env dc/mlbparks --from configmap/mlbparks-config configmap/mongodb-config

oc set triggers dc/mlbparks --remove-all
oc expose dc mlbparks --port 8080
oc expose svc mlbparks

##oc set volume dc/tasks --add --name=jboss-config --mount-path=/opt/eap/standalone/configuration/application-users.properties --sub-path=application-users.properties --configmap-name=tasks-config -n xyz-tasks-dev
##oc set volume dc/tasks --add --name=jboss-config1 --mount-path=/opt/eap/standalone/configuration/application-roles.properties --sub-path=application-roles.properties --configmap-name=tasks-config -n xyz-tasks-dev

echo '------ Start dev-pipeline ------'
#oc_project "$GUID" 'jenkins'

#oc start-build mlbparks-pipeline -n "${GUID}-jenkins"