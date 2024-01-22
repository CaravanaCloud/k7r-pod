#!/bin/bash
set -x

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
BIN_DIR="${DIR}/bin"
PATH="${BIN_DIR}:${PATH}"

export PREFIX="k7rirsa2"
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
envsubst < "install-config.aws-irsa.env.yaml" > "install-config.yaml"
DATE_STAMP=$(date +%Y%m%d%H%M%S)
cp "install-config.yaml" ".install-config.${DATE_STAMP}.yaml" 

RELEASE_IMAGE=$(openshift-install version | awk '/release image/ {print $3}')
echo "RELEASE_IMAGE=${RELEASE_IMAGE}" 

echo "Extracting credentials requests..."
oc adm release extract \
  --from=$RELEASE_IMAGE \
  --credentials-requests \
  --included \
  --install-config=./install-config.yaml \
  --to="credentials-requests"

echo "Adding Karpenter credentials request..."
cp ./credrequests/* ./credentials-requests

echo "Creating CCO resources..."
ccoctl aws create-all \
      --credentials-requests-dir="credentials-requests" \
      --name="${ENV_ID}cco" \
      --region="$AWS_REGION" \
      --output-dir="ccoctl-output"

echo "Creating manifests..."
openshift-install create manifests
cp ./ccoctl-output/manifests/* ./manifests/

echo "Creating cluster..."
sleep 5
openshift-install create cluster --log-level=debug

if [ $? -ne 0 ]; then
    echo "Create cluster failed, exiting."
    exit 1
fi

echo "Waiting for cluster to be ready..."
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

echo "Cluster is ready!"


# Karpenter
export KARPENTER_NAMESPACE="karpenter"
export KARPENTER_VERSION=v0.33.1
export K8S_VERSION=1.28

export AWS_PARTITION="aws"
export AWS_DEFAULT_REGION=$AWS_REGION
export AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
export TEMPOUT=$(mktemp)


# IRSA
export KARPENTER_SA="karpenter"
oc create sa "$KARPENTER_SA" -n "$KARPENTER_NAMESPACE"

helm upgrade --install karpenter oci://public.ecr.aws/karpenter/karpenter \
  --version "${KARPENTER_VERSION}" \
  --namespace "${KARPENTER_NAMESPACE}" \
  --create-namespace \
  --set "settings.clusterName=${CLUSTER_NAME}" \
  --set "settings.interruptionQueue=${CLUSTER_NAME}" \
  --set controller.resources.requests.cpu=1 \
  --set controller.resources.requests.memory=1Gi \
  --set controller.resources.limits.cpu=1 \
  --set controller.resources.limits.memory=1Gi \
  --wait


echo "create cluster done"