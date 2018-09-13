#!/bin/bash
source "${BIN_PATH:-./Infrastructure/bin}"/utils.sh

# Setup Production Project (initial active services: Green)
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
CLUSTER="na39.openshift.opentlc.com"

echo "Setting up Parks Production Environment in project ${GUID}-parks-prod"

# Code to set up the parks production project. It will need a StatefulSet MongoDB, and two applications each (Blue/Green) for NationalParks, MLBParks and Parksmap.
# The Green services/routes need to be active initially to guarantee a successful grading pipeline run.

oc_project "$GUID" 'parks-prod'

echo '------ Setting up the PROD project ------'
## Grant the correct permissions to the Jenkins service account
oc policy add-role-to-user edit "system:serviceaccount:${GUID}-jenkins:jenkins" -n "${GUID}-parks-prod"

## Grant the correct permissions to pull images from the development project
### https://github.com/debianmaster/openshift-examples/tree/master/pipeline-example#create-a-new-buildconfig-for-pipelines
oc policy add-role-to-group system:image-puller "system:serviceaccounts:${GUID}-parks-prod" -n "${GUID}-parks-dev"

## Grant the correct permissions for the ParksMap application to read back-end services (see the associated README file)
## https://github.com/wkulhanek/advdev_homework_template/tree/master/ParksMap
oc policy add-role-to-user view --serviceaccount=default -n "${GUID}-parks-prod"

echo '------ Set up a replicated MongoDB database via StatefulSet with at least three replicas ------'
source "${BIN_PATH:-./Infrastructure/bin}"/configs/mongodb_prod.sh
## https://docs.openshift.com/container-platform/3.9/using_images/db_images/mongodb.html#using-mongodb-replication
oc new-app -f "${TEMPLATES_PATH:-./Infrastructure/templates}"/mongodb-petset-persistent.yaml \
    -p MONGODB_DATABASE="$MONGODB_DATABASE" \
    --name="$MONGODB_SERVICE_NAME" \
    -n "${GUID}-parks-prod"

oc create configmap mongodb-config \
    --from-literal DB_HOST="$MONGODB_HOST" \
    --from-literal DB_PORT="$MONGODB_PORT" \
    --from-literal DB_NAME="$MONGODB_DATABASE" \
    --from-literal DB_DATABASE="$MONGODB_DATABASE" \
    --from-literal DB_REPLICASET="$MONGODB_REPLICASET" \
    -n "${GUID}-parks-prod"

## https://docs.openshift.com/container-platform/3.9/dev_guide/environment_variables.html#dev-guide-environment-variables
oc create secret generic mongodb-secret \
    --from-literal DB_USERNAME=$(oc set env sts/mongodb --list | grep MONGODB_USER | tr '=' '\n' | tail -1) \
    --from-literal DB_PASSWORD=$(oc set env sts/mongodb --list | grep MONGODB_PASSWORD | tr '=' '\n' | tail -1) \
    -n "${GUID}-parks-prod"

echo '------ Setting up the MLB Parks backend Application ------'
## https://github.com/wkulhanek/advdev_homework_template/tree/master/MLBParks
oc new-app -f "${TEMPLATES_PATH:-./Infrastructure/templates}"/parksmap_backend.yaml \
  -p "SERVICE=mlbparks-green" \
  -p "DEPLOYMENT=mlbparks-green" \
  -p "APPNAME=MLB Parks (Green)" \
  -p "IMAGE=docker-registry.default.svc:5000/${GUID}-parks-dev/mlbparks:latest" \
  -n "${GUID}-parks-prod"

oc new-app -f "${TEMPLATES_PATH:-./Infrastructure/templates}"/parksmap_backend.yaml \
  -p "SERVICE=mlbparks-blue" \
  -p "DEPLOYMENT=mlbparks-blue" \
  -p "APPNAME=MLB Parks (Blue)" \
  -p "IMAGE=docker-registry.default.svc:5000/${GUID}-parks-dev/mlbparks:latest" \
  -n "${GUID}-parks-prod"

## Make the Green service active initially to guarantee a Blue rollout upon the first pipeline run
oc rollout latest dc/mlbparks-green -n "${GUID}-parks-prod"
oc expose dc mlbparks-green --name=mlbparks -l type=parksmap-backend --port 8080 -n "${GUID}-parks-prod"
oc expose svc mlbparks -n "${GUID}-parks-prod"

echo '------ Setting up the Nationalparks backend Application ------'
## https://github.com/wkulhanek/advdev_homework_template/tree/master/Nationalparks
oc new-app -f "${TEMPLATES_PATH:-./Infrastructure/templates}"/parksmap_backend.yaml \
  -p "SERVICE=nationalparks-green" \
  -p "DEPLOYMENT=nationalparks-green" \
  -p "APPNAME=National Parks (Green)" \
  -p "IMAGE=docker-registry.default.svc:5000/${GUID}-parks-dev/nationalparks:latest" \
  -n "${GUID}-parks-prod"

oc new-app -f "${TEMPLATES_PATH:-./Infrastructure/templates}"/parksmap_backend.yaml \
  -p "SERVICE=nationalparks-blue" \
  -p "DEPLOYMENT=nationalparks-blue" \
  -p "APPNAME=National Parks (Blue)" \
  -p "IMAGE=docker-registry.default.svc:5000/${GUID}-parks-dev/nationalparks:latest" \
  -n "${GUID}-parks-prod"

## Make the Green service active initially to guarantee a Blue rollout upon the first pipeline run
oc rollout latest dc/nationalparks-green -n "${GUID}-parks-prod"
oc expose dc nationalparks-green --name=nationalparks -l type=parksmap-backend --port 8080 -n "${GUID}-parks-prod"
oc expose svc nationalparks -n "${GUID}-parks-prod"

echo '------ Setting up the ParksMap frontend Application ------'
## https://github.com/wkulhanek/advdev_homework_template/tree/master/ParksMap
oc new-app -f "${TEMPLATES_PATH:-./Infrastructure/templates}"/parksmap_frontend.yaml \
  -p "SERVICE=parksmap-green" \
  -p "NAME=parksmap-green" \
  -p "APPNAME=ParksMap (Green)" \
  -p "IMAGE=docker-registry.default.svc:5000/${GUID}-parks-dev/parksmap:latest" \
  -n "${GUID}-parks-prod"

oc new-app -f "${TEMPLATES_PATH:-./Infrastructure/templates}"/parksmap_frontend.yaml \
  -p "SERVICE=parksmap-blue" \
  -p "NAME=parksmap-blue" \
  -p "APPNAME=ParksMap (Blue)" \
  -p "IMAGE=docker-registry.default.svc:5000/${GUID}-parks-dev/parksmap:latest" \
  -n "${GUID}-parks-prod"

## Wait for the backend services completion
oc rollout status dc/mlbparks-green -n "${GUID}-parks-prod"
oc rollout status dc/nationalparks-green -n "${GUID}-parks-prod"

## Make the Green service active initially to guarantee a Blue rollout upon the first pipeline run
oc rollout latest dc/parksmap-green -n "${GUID}-parks-prod"
oc expose dc parksmap-green --name=parksmap --port 8080 -n "${GUID}-parks-prod"
oc expose svc parksmap -n "${GUID}-parks-prod"