#!/bin/bash
source ./utils.sh

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
oc policy add-role-to-user edit "system:serviceaccount:${GUID}-jenkins:jenkins"

## Grant the correct permissions to pull images from the development project
oc policy add-role-to-group view system:serviceaccount:${GUID}-parks-prod -n ${GUID}-parks-dev

## Grant the correct permissions for the ParksMap application to read back-end services (see the associated README file)
## https://github.com/wkulhanek/advdev_homework_template/tree/master/ParksMap
oc policy add-role-to-user view --serviceaccount=default

echo '------ Set up a replicated MongoDB database via StatefulSet with at least three replicas ------'
source ./configs/mongodb_prod.sh
## https://docs.openshift.com/container-platform/3.9/using_images/db_images/mongodb.html#using-mongodb-replication
oc new-app -f ../templates/mongodb-petset-persistent.yaml \
    -p MONGODB_DATABASE="$MONGODB_DATABASE" \
    --name="$MONGODB_SERVICE_NAME"

oc create configmap mongodb-config \
    --from-literal DB_HOST="$MONGODB_HOST" \
    --from-literal DB_PORT="$MONGODB_PORT" \
    --from-literal DB_NAME="$MONGODB_DATABASE" \
    --from-literal DB_DATABASE="$MONGODB_DATABASE" \
    --from-literal DB_REPLICASET="$MONGODB_REPLICASET"

## https://docs.openshift.com/container-platform/3.9/dev_guide/environment_variables.html#dev-guide-environment-variables
oc create secret generic mongodb-secret \
    --from-literal DB_USERNAME=$(oc set env sts/mongodb --list | grep MONGODB_USER | tr '=' '\n' | tail -1) \
    --from-literal DB_PASSWORD=$(oc set env sts/mongodb --list | grep MONGODB_PASSWORD | tr '=' '\n' | tail -1)

echo '------ Setting up the MLB Parks backend Application ------'
## https://github.com/wkulhanek/advdev_homework_template/tree/master/MLBParks
:'
oc new-app "${GUID}-parks-dev/mlbparks:latest" --name=mlbparks-prod \
  -e APPNAME="MLB Parks (Prod)" \
  -l type=parksmap-backend \
  --allow-missing-imagestream-tags=true --allow-missing-images=true

oc set env dc/mlbparks --from configmap/mongodb-config
oc set env dc/mlbparks --from secret/mongodb-secret

oc set triggers dc/mlbparks --remove-all
oc expose dc mlbparks --port 8080
oc expose svc mlbparks

oc set probe dc/mlbparks --readiness --get-url=http://:8080/ws/healthz/ \
  --initial-delay-seconds=30 --period-seconds=10 --timeout-seconds=5
oc set probe dc/mlbparks --liveness --get-url=http://:8080/ws/healthz/ \
  --initial-delay-seconds=45 --period-seconds=10 --timeout-seconds=5
'
oc process -f ../templates/mlbparks.yaml \
  -p "NAME=mlbparks-green" \
  -p "APPNAME=MLB Parks (Green)" \
  | oc create -f -

echo '------ Setting up the Nationalparks backend Application ------'
## https://github.com/wkulhanek/advdev_homework_template/tree/master/Nationalparks
oc new-app "${GUID}-parks-dev/nationalparks:latest" \
  --name=nationalparks \
  -e APPNAME="National Parks (Prod)" \
  -l type=parksmap-backend \
  --allow-missing-imagestream-tags=true --allow-missing-images=true

oc set env dc/nationalparks --from configmap/mongodb-config
oc set env dc/nationalparks --from secret/mongodb-secret

oc set triggers dc/nationalparks --remove-all
oc expose dc nationalparks --port 8080
oc expose svc nationalparks

oc set probe dc/nationalparks --readiness --get-url=http://:8080/ws/healthz/ \
  --initial-delay-seconds=30 --period-seconds=10 --timeout-seconds=5
oc set probe dc/nationalparks --liveness --get-url=http://:8080/ws/healthz/ \
  --initial-delay-seconds=45 --period-seconds=10 --timeout-seconds=5

echo '------ Setting up the ParksMap frontend Application ------'
## https://github.com/wkulhanek/advdev_homework_template/tree/master/ParksMap
oc new-app "${GUID}-parks-dev/parksmap:latest" --name=parksmap \
  --allow-missing-imagestream-tags=true --allow-missing-images=true

oc set env dc/parksmap -e "APPNAME=ParksMap (Prod)"

oc policy add-role-to-user view --serviceaccount=default

oc set triggers dc/parksmap --remove-all
oc expose dc parksmap --port 8080
oc expose svc parksmap

oc set probe dc/parksmap --readiness --get-url=http://:8080/ws/healthz/ \
  --initial-delay-seconds=30 --period-seconds=10 --timeout-seconds=5
oc set probe dc/parksmap --liveness --get-url=http://:8080/ws/healthz/ \
  --initial-delay-seconds=45 --period-seconds=10 --timeout-seconds=5

echo '------ Start prod-pipeline ------'
#oc_project "$GUID" 'jenkins'

#oc start-build mlbparks-pipeline -n "${GUID}-jenkins"