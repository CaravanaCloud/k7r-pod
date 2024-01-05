#!/bin/bash
set -x

CLUSTER_NAME="k7rokdc"
BASE_DOMAIN="devcluster.openshift.com"
HOSTED_ZONE_ID="Z3URY6TWQ91KVV"
RR_NAME="api.$CLUSTER_NAME.$BASE_DOMAIN"
RR_TYPE="A"

CHANGE_BATCH="{\"Changes\": [{\"Action\": \"DELETE\",\"ResourceRecordSet\": {\"Name\": \"$RR_NAME\",\"Type\": \"$RR_TYPE\"}}}]}"

aws route53 change-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --change-batch 
