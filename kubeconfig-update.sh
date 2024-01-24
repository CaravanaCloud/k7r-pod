#!/bin/bash

mkdir -p  $HOME/.kube/
cp -a auth/kubeconfig $HOME/.kube/config

sudo ln -sf /workspace/k7r-pod/bin/oc /usr/local/bin/oc