#!/usr/bin/env bash -l

. credentials/guid.sh
. credentials/opentlc.sh
. credentials/cluster.sh

oc_connect () {
  ./oc_connect.sh
  next_step setup_projects
}

setup_projects () {
  ./setup_projects.sh "$GUID" "$USER"
  next_step setup_jenkins
}

setup_jenkins () {
  oc project ${GUID}-jenkins
  ./setup_jenkins.sh "$GUID" "$REPO" "$CLUSTER"
##  next_step setup_projects
}


next_step () {
  export STEP="$1"
  echo "--------------------------------------------"
  echo "Next Step: ${STEP}"
  echo ""
  eval "${STEP}"
}

next_step "${1:-oc_connect}"
