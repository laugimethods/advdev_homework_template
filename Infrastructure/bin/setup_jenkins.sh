#!/bin/bash
source "${BIN_PATH:-./Infrastructure/bin}"/utils.sh

# Setup Jenkins Project
if [ "$#" -ne 3 ]; then
    echo "Usage:"
    echo "  $0 GUID REPO CLUSTER"
    echo "  Example: $0 wkha https://github.com/wkulhanek/ParksMap na39.openshift.opentlc.com"
    exit 1
fi

GUID=$1
REPO=$2
CLUSTER=$3
# JENKINS_PASSWORD=$4

echo "Setting up Jenkins in project ${GUID}-jenkins from Git Repo ${REPO} for Cluster ${CLUSTER}"

# Code to set up the Jenkins project to execute the
# three pipelines.
# This will need to also build the custom Maven Slave Pod
# Image to be used in the pipelines.
# Finally the script needs to create three OpenShift Build
# Configurations in the Jenkins Project to build the
# three micro services. Expected name of the build configs:
# * mlbparks-pipeline
# * nationalparks-pipeline
# * parksmap-pipeline
# The build configurations need to have two environment variables to be passed to the Pipeline:
# * GUID: the GUID used in all the projects
# * CLUSTER: the base url of the cluster used (e.g. na39.openshift.opentlc.com)

oc_project "$GUID" 'jenkins'

echo '------ Create the Jenkins App ------'

oc new-app jenkins-persistent --param ENABLE_OAUTH=true --param MEMORY_LIMIT=2Gi --param VOLUME_CAPACITY=4Gi -n "${GUID}-jenkins"

sed -e "s/\${GUID}/$GUID/" ../templates/jenkins_configmap.yaml > ./tmp/jenkins_configmap.yaml
oc create configmap jenkins --from-file=./tmp/jenkins_configmap.yaml

: ''

echo '------ Build Skopeo Docker Image ------'
# https://docs.openshift.com/container-platform/3.9/dev_guide/builds/build_output.html

oc create imagestream jenkins-slave-appdev
oc create -f ../templates/BuildConfig_Skopeo
oc start-build skopeo-build

echo '------- Create BuildConfig_MLBParks ---------'
# https://docs.openshift.com/container-platform/3.9/dev_guide/builds/build_strategies.html#jenkinsfile
# https://docs.openshift.com/container-platform/3.9/dev_guide/builds/build_environment.html#using-build-fields-as-environment-variables

sed "s/\${GUID}/${GUID}/g;s/\${CLUSTER}/${CLUSTER}/g;s/\${FAST_MODE}/${FAST_MODE:-false}/g" ../templates/BuildConfig_MLBParks | oc create -f -

echo '------- Create BuildConfig_Nationalparks ---------'
sed "s/\${GUID}/${GUID}/g;s/\${CLUSTER}/${CLUSTER}/g;s/\${FAST_MODE}/${FAST_MODE:-false}/g" ../templates/BuildConfig_Nationalparks | oc create -f -

echo '------- Create BuildConfig_ParksMap ---------'
# See https://github.com/jenkinsci/kubernetes-plugin#declarative-pipeline
sed "s/\${GUID}/${GUID}/g;s/\${CLUSTER}/${CLUSTER}/g;s/\${FAST_MODE}/${FAST_MODE:-false}/g" ../templates/BuildConfig_ParksMap | oc create -f -
