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

echo '------ Setting up MongoDB ------'
oc_project "$GUID" 'parks-dev'

:'
. credentials/mongodb_dev.sh
# https://docs.openshift.com/container-platform/3.9/using_images/db_images/mongodb.html
oc new-app \
#    -e MONGODB_USER="$MONGODB_USER_DEV" \
#    -e MONGODB_PASSWORD="$MONGODB_PASSWORD_DEV" \
#    -e MONGODB_DATABASE="$MONGODB_DATABASE_DEV" \
#    -e MONGODB_ADMIN_PASSWORD="$MONGODB_ADMIN_PASSWORD_DEV" \
    mongodb-ephemeral
'

echo '------ Create dev-pipeline ------'
oc_project "$GUID" 'jenkins'

# https://docs.openshift.com/container-platform/3.9/dev_guide/builds/build_strategies.html#jenkinsfile
#oc replace -f https://github.com/laugimethods/advdev_homework_template/tree/master/Infrastructure/templates/dev-pipeline.yaml
oc create -f ../templates/dev-pipeline.yaml
oc set env buildconfigs/dev-pipeline GUID="$GUID"
oc set env buildconfigs/dev-pipeline CLUSTER="$CLUSTER"
#oc start-build dev-pipeline -n "${GUID}-jenkins"