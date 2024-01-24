#!/bin/bash
set -x

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
BIN_DIR="${DIR}/bin"
PATH="${BIN_DIR}:${PATH}"

export PREFIX="k7r"
export ENV_ID="$(head -c 4 /etc/machine-id)"
export TODAY="$(date +%d%b | tr '[:upper:]' '[:lower:]')"
export CLUSTER_NAME="$PREFIX$TODAY$ENV_ID"
export BASE_DOMAIN="lab-scaling.devcluster.openshift.com"
echo "Creating cluster $CLUSTER_NAME.$BASE_DOMAIN"

export AWS_REGION="us-east-1"
export SSH_KEY=$(cat ~/.ssh/id_rsa.pub)
export INSTANCE_TYPE=${INSTANCE_TYPE:-"m6.2xlarge"}

echo "Checking AWS $AWS_REGION ($INSTANCE_TYPE)"
aws sts get-caller-identity

echo "Generating install-config"
envsubst < "install-config.aws-irsa.env.yaml" > "install-config.yaml"
DATE_STAMP=$(date +%Y%m%d%H%M%S)
cp "install-config.yaml" ".install-config.${DATE_STAMP}.yaml" 


RELEASE_IMAGE=$(openshift-install version | awk '/release image/ {print $3}')

echo "Extracting credentials requests from RELEASE_IMAGE=${RELEASE_IMAGE}" 
oc adm release extract \
  --from=$RELEASE_IMAGE \
  --credentials-requests \
  --included \
  --install-config=./install-config.yaml \
  --to=".cco-requests"

# echo "Adding Karpenter credentials request..."
# cp ./k7r-credential-request/* ./.cco-requests

echo "Creating CCO resources..."
ccoctl aws create-all \
      --credentials-requests-dir=".cco-requests" \
      --name="${ENV_ID}cco" \
      --region="$AWS_REGION" \
      --output-dir=".cco-out"

echo "Creating manifests..."
openshift-install create manifests
cp ./.cco-out/manifests/* ./manifests/
cp -a ./manifests ./.manifests.${DATE_STAMP}

echo "Creating cluster..."
sleep 5
openshift-install create cluster --log-level=debug

if [ $? -ne 0 ]; then
    echo "Create cluster failed, exiting."
    exit 1
fi

# echo "Waiting for cluster to be ready..."
# openshift-install wait-for install-complete --log-level=debug

if [ -f "$HOME/.kube/config" ]; then
    echo "Backing up existing kubeconfig"
    mv $HOME/.kube/config ~/.kube/config.bak.$(date +%Y%m%d%H%M%S)
fi
echo "Setting up kubeconfig"
mkdir -p "$HOME/.kube"
cp auth/kubeconfig ~/.kube/config

echo "Checking cluster access"
if kubectl cluster-info; then
  echo "Kubernetes API seems OK"
else
  echo "Kubernetes API is not responding"
  exit 1
fi

echo "Cluster is ready!"
exit 0
