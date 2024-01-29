#!/usr/bin/env bash
set -x
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"


export ENV_ID="k7r$RANDOM"
export DATE_STAMP=$(date +%d%b | tr "[:upper:]" "[:lower:]")
export CLUSTER_NAME="$ENV_ID"
export INSTALL_DIR="${DIR}/.install-dir/$CLUSTER_NAME"

# check if openshift-insall is not available
if ! command -v openshift-install &> /dev/null
then
    echo "openshift-install could not be found. Installing..."
    source ./bin/install-openshift-install.sh
fi

echo "Creating new cluster [$ENV_ID]"
source ./create-cluster.aws-e2e.sh

echo "Soundcheck"
oc cluster-info
oc get nodes

echo "Destroying cluster [$ENV_ID]"
source ./destroy-cluster.e2e.sh