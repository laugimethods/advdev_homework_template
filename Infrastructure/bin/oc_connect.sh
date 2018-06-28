. credentials/guid.sh
. credentials/opentlc.sh
. credentials/cluster.sh
oc login -u "$OPENTLC_UserID" -p "$OPENTLC_Password" "master.${CLUSTER}"