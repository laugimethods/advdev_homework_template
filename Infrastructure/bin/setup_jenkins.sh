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

# https://docs.openshift.com/container-platform/3.9/using_images/other_images/jenkins.html#configuring-the-jenkins-kubernetes-plug-in
##oc create configmap jenkins-slave --from-file=../templates/jenkins_configmap.yaml
sed -e "s/\${GUID}/$GUID/" ../templates/jenkins_configmap.tmpl.yaml > ./jenkins_configmap.yaml
oc create configmap jenkins-slave --from-file=./jenkins_configmap.yaml

oc new-app -f ../templates/jenkins.json -p MEMORY_LIMIT=2Gi -p ENABLE_OAUTH=false

: '
oc create -f ../templates/dev-pipeline.yaml
oc set env buildconfigs/dev-pipeline GUID="$GUID"

# https://www.opentlc.com/labs/ocp_advanced_development/04_1_CICD_Tools_Solution_Lab.html#_work_with_custom_jenkins_slave_pod
pushd ../docker/skopeo
docker build . -t "docker-registry-default.apps.na39.openshift.opentlc.com/${GUID}-jenkins/jenkins-slave-maven-skopeo:v3.9"

docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  "docker-registry-default.apps.na39.openshift.opentlc.com/${GUID}-jenkins/jenkins-slave-maven-skopeo:v3.9" \
  skopeo copy --dest-tls-verify=false --dest-creds=$(oc whoami):$(oc whoami -t) \
  docker-daemon:docker-registry-default.apps.na39.openshift.opentlc.com/${GUID}-jenkins/jenkins-slave-maven-skopeo:v3.9 \
  docker://docker-registry-default.apps.na39.openshift.opentlc.com/${GUID}-jenkins/jenkins-slave-maven-skopeo:v3.9
popd
'
