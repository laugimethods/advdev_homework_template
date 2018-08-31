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

oc new-build --binary=true --name="mlbparks" jboss-eap70-openshift:1.6
oc new-app "${GUID}-parks-dev/mlbparks:0.0-0" --name=mlbparks --allow-missing-imagestream-tags=true
oc set triggers dc/mlbparks --remove-all
oc expose dc mlbparks --port 8080
oc expose svc mlbparks
oc create configmap mlbparks-config --from-literal="APPNAME=MLB Parks (Dev)"
##oc set volume dc/tasks --add --name=jboss-config --mount-path=/opt/eap/standalone/configuration/application-users.properties --sub-path=application-users.properties --configmap-name=tasks-config -n xyz-tasks-dev
##oc set volume dc/tasks --add --name=jboss-config1 --mount-path=/opt/eap/standalone/configuration/application-roles.properties --sub-path=application-roles.properties --configmap-name=tasks-config -n xyz-tasks-dev

echo '------ Setting up MongoDB ------'

source ./credentials/mongodb_dev.sh
# https://docs.openshift.com/container-platform/3.9/using_images/db_images/mongodb.html
oc new-app \
    -p MONGODB_USER="$MONGODB_USER_DEV" \
    -p MONGODB_PASSWORD="$MONGODB_PASSWORD_DEV" \
    -p MONGODB_DATABASE="$MONGODB_DATABASE_DEV" \
    -p MONGODB_ADMIN_PASSWORD="$MONGODB_ADMIN_PASSWORD_DEV" \
    mongodb-ephemeral

echo '-------- ConfigMap Creation -----------'
oc delete configmap mlbparks-config --ignore-not-found=true
oc create configmap mlbparks-config --from-file=../templates/parks-dev.properties

echo '------ Start dev-pipeline ------'
#oc_project "$GUID" 'jenkins'

#oc start-build mlbparks-pipeline -n "${GUID}-jenkins"