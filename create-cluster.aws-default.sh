#!/bin/bash
set -x

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
BIN_DIR="${DIR}/bin"
PATH="${BIN_DIR}:${PATH}"

export PREFIX="k7rcluster"
export TODAY="$(date +%d%b | tr '[:upper:]' '[:lower:]')"
export CLUSTER_NAME="$PREFIX$TODAY"
export BASE_DOMAIN="devcluster.openshift.com"
export AWS_REGION="us-east-1"
export SSH_KEY=$(cat ~/.ssh/id_rsa.pub)
export INSTANCE_TYPE=${INSTANCE_TYPE:-"m6a.2xlarge"}

echo "Creating cluster $CLUSTER_NAME.$BASE_DOMAIN"

# AWS Check
echo "AWS: $AWS_REGION ($INSTANCE_TYPE)"
aws sts get-caller-identity

# Generate install config
envsubst < "install-config.aws-default.env.yaml" > "install-config.yaml"
cp "install-config.yaml" "install-config.bak.yaml" 

echo "Creating cluster..."
sleep 5
openshift-install create cluster --log-level=debug

if [ $? -ne 0 ]; then
    echo "Create cluster failed, exiting."
    exit 1
fi

openshift-install wait-for install-complete --log-level=debug

mkdir -p "$HOME/.kube"
if [ -f "$HOME/.kube/config" ]; then
    mv $HOME/.kube/config ~/.kube/config.bak.$(date +%Y%m%d%H%M%S)
fi
cp auth/kubeconfig ~/.kube/config

if kubectl cluster-info; then
  echo "Kubernetes API seems OK"
else
  echo "Kubernetes API is not responding"
  exit 1
fi

echo "create cluster done"