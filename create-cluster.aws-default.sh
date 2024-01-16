#!/bin/bash
set -x

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
BIN_DIR="${DIR}/bin"
PATH="${BIN_DIR}:${PATH}"


export CLUSTER_NAME="k7rclusterd"
export BASE_DOMAIN="devcluster.openshift.com"
export AWS_REGION="us-east-1"
export SSH_KEY=$(cat ~/.ssh/id_rsa.pub)
export INSTANCE_TYPE="t3a.2xlarge"

# Generate install config
envsubst < "install-config.aws-default.env.yaml" > "install-config.yaml"
cp "install-config.yaml" "install-config.bak.yaml" 

aws sts get-caller-identity

sleep 5
openshift-install create cluster | tee .openshift_create-cluster.log

echo "create cluster done"