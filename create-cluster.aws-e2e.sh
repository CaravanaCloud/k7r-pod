#!/bin/bash
set -x
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

PULL_SECRET_FILE="${HOME}/.openshift/pull-secret-latest.json"
RELEASE_IMAGE=quay.io/openshift-release-dev/ocp-release:${VERSION}-x86_64
SSH_PUB_KEY_FILE="$HOME/.ssh/id_rsa.pub"

export CLUSTER_BASE_DOMAIN="lab-scaling.devcluster.openshift.com"
export REGION="us-east-1"
export SSH_KEY=$(cat $SSH_PUB_KEY_FILE)


rm -rf $INSTALL_DIR
mkdir -p $INSTALL_DIR

echo "> Creating ${INSTALL_DIR}/install-config.yaml"
mkdir -p ${INSTALL_DIR}
envsubst < install-config.aws-e2e.env.yaml > ${INSTALL_DIR}/install-config.yaml 
cp ${INSTALL_DIR}/install-config.yaml ${INSTALL_DIR}/install-config.bkp.yaml

openshift-install create cluster --dir=$INSTALL_DIR --log-level=debug
if [ $? -ne 0 ]; then
    echo "Create cluster failed, exiting."
    exit 1
fi

echo "Updating kubeconfig"
if [ -f "$HOME/.kube/config" ]; then
    echo "Backing up existing kubeconfig"
    mv $HOME/.kube/config ~/.kube/config.bak.$(date +%Y%m%d%H%M%S)
fi
mkdir -p "$HOME/.kube"
cp ${INSTALL_DIR}/auth/kubeconfig ~/.kube/config

echo "Checking cluster access"
if kubectl cluster-info; then
  echo "Kubernetes API seems OK"
else
  echo "Kubernetes API is not responding"
  exit 1
fi

echo "Cluster is ready!"
