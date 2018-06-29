#!/bin/bash
# Setup Nexus Project
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up Nexus in project $GUID-nexus"

#setup_nexus.sh: This script will need to do the following in the $GUID-nexus project:
#Create a new Nexus instance from docker.io/sonatype/nexus3:latest.
#Configure Nexus appropriately for resources, deployment strategy, persistent volumes, readiness and liveness probes.
#When Nexus is running populate Nexus with the correct repositories.
#Expose the Container Registry

while : ; do
  echo "Try to connect to the ${GUID}-nexus Project..."
  oc project ${GUID}-nexus
  [[ "$?" == "1" ]] || break
  echo "Not Ready Yet. Sleeping 5 seconds."
  sleep 5
done

# https://docs.openshift.com/container-platform/3.5/dev_guide/app_tutorials/maven_tutorial.html#nexus-setting-up-nexus

# Ideally just calls a template
oc new-app -f ../templates/nexus.yml

# Code to set up the Nexus. It will need to
# * Create Nexus
# * Set the right options for the Nexus Deployment Config
# * Load Nexus with the right repos
# * Configure Nexus as a docker registry
# Hint: Make sure to wait until Nexus if fully up and running
#       before configuring nexus with repositories.
#       You could use the following code:
echo -n "Checking if Nexus is Ready..."
while : ; do
##  oc get pod -n ${GUID}-nexus|grep '\-2\-'|grep -v deploy|grep "1/1"
  oc get pod -n ${GUID}-nexus|grep -v deploy|grep "1/1"
  [[ "$?" == "1" ]] || break
  echo -n "."
  sleep 10
done
