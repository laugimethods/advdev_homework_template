#!/bin/bash
source ./utils.sh

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

oc_project "$GUID" 'nexus'

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

echo -n "Configuring Nexus"
# https://www.opentlc.com/labs/ocp_advanced_development/04_1_CICD_Tools_Solution_Lab.html#_configure_nexus

curl -o setup_nexus3.sh -s https://raw.githubusercontent.com/wkulhanek/ocp_advanced_development_resources/master/nexus/setup_nexus3.sh
chmod +x setup_nexus3.sh
./setup_nexus3.sh admin admin123 http://$(oc get route nexus3 --template='{{ .spec.host }}')
rm setup_nexus3.sh

echo -n "Configuring Nexus Service and Route"

oc expose dc nexus3 --port=5000 --name=nexus-registry
oc create route edge nexus-registry --service=nexus-registry --port=5000