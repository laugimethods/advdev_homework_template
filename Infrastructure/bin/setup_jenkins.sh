#!/bin/bash
# Setup Jenkins Project
if [ "$#" -ne 4 ]; then
    echo "Usage:"
    echo "  $0 GUID REPO CLUSTER JENKINS_PASSWORD"
    echo "  Example: $0 wkha https://github.com/wkulhanek/ParksMap na39.openshift.opentlc.com"
    exit 1
fi

GUID=$1
REPO=$2
CLUSTER=$3
JENKINS_PASSWORD=$4
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

while : ; do
  echo "Try to connect to the ${GUID}-jenkins Project..."
  oc project ${GUID}-jenkins
  [[ "$?" == "1" ]] || break
  echo "Not Ready Yet. Sleeping 5 seconds."
  sleep 5
done

# Fails when used in conjunction with `setup_projects.sh`: `serviceaccount "jenkins" not found`
#oc new-app -f ../templates/jenkins.yml -p HOST="jenkins-${GUID}-jenkins.apps.${CLUSTER}"

# See https://docs.openshift.com/container-platform/3.9/using_images/other_images/jenkins.html
oc new-app \
    -e JENKINS_PASSWORD=${JENKINS_PASSWORD} \
    -e OPENSHIFT_ENABLE_OAUTH=false \
    jenkins-persistent