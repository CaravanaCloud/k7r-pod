#!/bin/bash
set -x
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"


VERSION="4.14.8"
PULL_SECRET_FILE="${HOME}/.openshift/pull-secret-latest.json"
RELEASE_IMAGE=quay.io/openshift-release-dev/ocp-release:${VERSION}-x86_64
CLUSTER_NAME="k7rmtuliob"
INSTALL_DIR="${DIR}/.install-dir/$CLUSTER_NAME"
CLUSTER_BASE_DOMAIN="lab-scaling.devcluster.openshift.com"
REGION="us-east-1"
SSH_PUB_KEY_FILE="$HOME/.ssh/id_rsa.pub"

mkdir -p $INSTALL_DIR && cd $INSTALL_DIR

# oc adm release extract \
#     --tools quay.io/openshift-release-dev/ocp-release:${VERSION}-x86_64 \
#     -a ${PULL_SECRET_FILE}

# tar xvfz openshift-client-linux-${VERSION}.tar.gz
# tar xvfz openshift-install-linux-${VERSION}.tar.gz

echo "> Creating install-config.yaml"
# Create a single-AZ install config
mkdir -p ${INSTALL_DIR}
cat <<EOF | envsubst > ${INSTALL_DIR}/install-config.yaml
apiVersion: v1
baseDomain: ${CLUSTER_BASE_DOMAIN}
metadata:
  name: "${CLUSTER_NAME}"
platform:
  aws:
    region: ${REGION}
    propagateUserTags: true
    userTags:
      cluster_name: $CLUSTER_NAME
      Environment: cluster
publish: External
pullSecret: '$(cat ${PULL_SECRET_FILE} |awk -v ORS= -v OFS= '{$1=$1}1')'
sshKey: |
  $(cat ${SSH_PUB_KEY_FILE})
EOF

echo ">> install-config.yaml created: "
cp ${INSTALL_DIR}/install-config.yaml ${INSTALL_DIR}/install-config.bkp.yaml

openshift-install create cluster --dir=$INSTALL_DIR --log-level=debug

###
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
