#!/bin/bash
set -x
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

echo "Destroying cluster [$ENV_ID]"

export CLUSTER_NAME="$ENV_ID"
export INSTALL_DIR="${DIR}/.install-dir/$CLUSTER_NAME"

openshift-install destroy cluster --dir=$INSTALL_DIR --log-level=debug
