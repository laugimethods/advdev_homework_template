#!/bin/bash
# Setup Sonarqube Project
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up Sonarqube in project $GUID-sonarqube"

# setup_sonar.sh: This script will need to do the following in the $GUID-sonarqube project:
# Create a new PostgreSQL database
# Create a new SonarQube instance from docker.io/wkulhanek/sonarqube:6.7.4.
# Configure SonarQube appropriately for resources, deployment strategy, persistent volumes, readiness and liveness probes.

while : ; do
  echo "Try to connect to the ${GUID}-sonarqube Project..."
  oc project ${GUID}-sonarqube
  [[ "$?" == "1" ]] || break
  echo "Not Ready Yet. Sleeping 5 seconds."
  sleep 5
done

# Code to set up the SonarQube project.
# Ideally just calls a template
# oc new-app -f ../templates/sonarqube.yaml --param .....

# https://github.com/OpenShiftDemos/sonarqube-openshift-docker

oc new-app -f ../templates/sonarqube-postgresql-template.yaml --param=SONARQUBE_VERSION=6.7