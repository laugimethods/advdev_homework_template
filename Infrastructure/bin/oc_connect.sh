. credentials/guid.sh
. credentials/opentlc.sh
. credentials/cluster.sh
oc login -u "$OPENTLC_UserID" -p "$OPENTLC_Password" "master.${CLUSTER}"
echo "Connected to master.${CLUSTER}" as "$OPENTLC_UserID" user.