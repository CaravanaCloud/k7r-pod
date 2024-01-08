#!/bin/bash
set -x

CLUSTER_NAME="k7rokdc"
BASE_DOMAIN="devcluster.openshift.com"
HOSTED_ZONE_ID="Z3URY6TWQ91KVV"
RR_NAME="api.$CLUSTER_NAME.$BASE_DOMAIN"
RR_TYPE="A"
RR_ALIAS="k7rokdc-5rz22-ext-72c099cd57fc95c2.elb.us-east-1.amazonaws.com."

# aws route53 list-resource-record-sets --hosted-zone-id Z3URY6TWQ91KVV 
# aws route53 change-resource-record-sets --hosted-zone-id Z3URY6TWQ91KVV --change-batch file://payload.json

CHANGE_BATCH="{\"Changes\": [{\"Action\": \"DELETE\", \"ResourceRecordSet\": {\"Name\": \"$RR_NAME\", \"Type\": \"$RR_TYPE\", \"AliasTarget\": {
\"HostedZoneId\": \"$HOSTED_ZONE_ID\", \"DNSName\": \"$RR_ALIAS\", \"EvaluateTargetHealth\": false }  }}]}"

echo $CHANGE_BATCH | jq
aws route53 change-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --change-batch "$CHANGE_BATCH"
