#!/bin/bash
set -x

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
BIN_DIR="${DIR}/bin"

# Generate install config
envsubst < "${DIR}/install-config.aws-default.env.yaml" > "${DIR}/install-config.yaml"

sleep 5
"${BIN_DIR}/openshift-install" create cluster | tee .openshift_create-cluster.log

echo "create cluster done"