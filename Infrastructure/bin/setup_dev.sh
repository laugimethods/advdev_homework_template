#!/bin/bash
source ./utils.sh

# Setup Development Project
if [ "$#" -ne 2 ]; then
    echo "Usage:"
    echo "  $0 GUID CLUSTER"
    exit 1
fi

GUID=$1
CLUSTER=$2
echo "Setting up Parks Development Environment in project ${GUID}-parks-dev"

# Code to set up the parks development project.

# To be Implemented by Student

# https://docs.openshift.com/container-platform/3.9/dev_guide/builds/build_strategies.html#jenkinsfile
#oc replace -f https://github.com/laugimethods/advdev_homework_template/tree/master/Infrastructure/templates/dev-pipeline.yaml

oc_project "$GUID" 'jenkins'

echo '------ Create dev-pipeline ------'
oc create -f ../templates/dev-pipeline.yaml
oc set env buildconfigs/dev-pipeline GUID="$GUID"
oc set env buildconfigs/dev-pipeline CLUSTER="$CLUSTER"
#oc start-build dev-pipeline -n 65bb-jenkins