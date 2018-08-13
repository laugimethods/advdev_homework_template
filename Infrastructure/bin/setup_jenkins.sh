#!/bin/bash
source ./utils.sh

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

: '
'

## Not required since the Jenkinsfile are already provinding the required podTemplate definition ##
# https://docs.openshift.com/container-platform/3.9/using_images/other_images/jenkins.html#configuring-the-jenkins-kubernetes-plug-in
sed -e "s/\${GUID}/$GUID/" ../templates/jenkins_configmap.tmpl.yaml > ./tmp/jenkins_configmap.yaml
oc create configmap jenkins --from-file=./tmp/jenkins_configmap.yaml

echo '------ New Jenkins Persistent App ------'
## oc edit template -n openshift jenkins-persistent
oc new-app -p ENABLE_OAUTH=false -f ../templates/jenkins-persistent.yml
  #jenkins.json -p MEMORY_LIMIT=2Gi
  #-p ENABLE_OAUTH=false

echo '------ Build Skopeo Docker Image ------'
# https://www.opentlc.com/labs/ocp_advanced_development/04_1_CICD_Tools_Solution_Lab.html#_work_with_custom_jenkins_slave_pod
pushd ../docker/skopeo
docker build . -t jenkins-slave-appdev:v3.9
popd

echo '------ Deploy the Skopeo Docker Image into the OpenShift Repository ------'
docker run -d --rm -it -v /var/run/docker.sock:/var/run/docker.sock --name skopeo_bash jenkins-slave-appdev:v3.9 bash

docker exec -it skopeo_bash \
  skopeo copy --dest-tls-verify=false --dest-creds=$(oc whoami):$(oc whoami -t) \
    docker-daemon:jenkins-slave-appdev:v3.9 \
    "docker://docker-registry-default.apps.na39.openshift.opentlc.com/${GUID}-jenkins/jenkins-slave-appdev:latest"

docker rm -f skopeo_bash

#docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -u 1001 jenkins-slave-appdev:v3.9 \
#  skopeo copy --dest-tls-verify=false --dest-creds=$(oc whoami):$(oc whoami -t) \
#    docker-daemon:jenkins-slave-appdev:v3.9 \
#    "docker://docker-registry-default.apps.na39.openshift.opentlc.com/${GUID}-jenkins/jenkins-slave-appdev:latest"
