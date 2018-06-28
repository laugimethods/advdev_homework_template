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
  next_step end
}

end () {
  echo "------------------- END --------------------"
}

first_step () {
  export STEP="$1"
  export STOP="$2"
  echo "--------------------------------------------"
  echo "First Step: ${STEP}"
  echo ""
  eval "${STEP}"
}

next_step () {
  ## Move to the next Step if STOP is not requested, otherwise exit
  [[ $STOP == STOP ]] && echo "------------- STOP requested -------------" && exit 1
  export STEP="$1"
  echo "--------------------------------------------"
  echo "Next Step: ${STEP}"
  echo ""
  eval "${STEP}"
}

first_step "${1:-oc_connect}" "$2"
