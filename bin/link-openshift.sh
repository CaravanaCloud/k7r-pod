#!/bin/bash
set -x

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

echo "System links"
sudo ln -sf "${DIR}/kubectl" "/usr/local/bin/kubectl"
sudo ln -sf "${DIR}/oc" "/usr/local/bin/oc"
sudo ln -sf "${DIR}/openshift-install" "/usr/local/bin/openshift-install" 
sudo ln -sf "${DIR}/ccoctl" "/usr/local/bin/ccoctl" 

mkdir -p $HOME/.kube
cp "${DIR}/../auth/kubeconfig" "$HOME/.kube/config"

oc version client
oc get nodes

