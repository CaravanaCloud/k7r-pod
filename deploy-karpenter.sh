#!/bin/bash 
export KARPENTER_NAMESPACE=karpenter
export KARPENTER_VERSION=v0.27.0
export CLUSTER_NAME=$(oc get infrastructures cluster -o jsonpath='{.status.infrastructureName}')
export WORKER_PROFILE=$(oc get machineset -n openshift-machine-api $(oc get machineset -n openshift-machine-api -o jsonpath='{.items[0].metadata.name}') -o json | jq -r '.spec.template.spec.providerSpec.value.iamInstanceProfile.id')
export KUBE_ENDPOINT=$(oc get infrastructures cluster -o jsonpath='{.status.apiServerInternalURI}')

cat <<EOF
KARPENTER_NAMESPACE=$KARPENTER_NAMESPACE
KARPENTER_VERSION=$KARPENTER_VERSION
CLUSTER_NAME=$CLUSTER_NAME
WORKER_PROFILE=$WORKER_PROFILE
EOF


# Create the karpenter chart/helm repo
# https://artifacthub.io/packages/helm/karpenter/karpenter
helm repo add karpenter https://charts.karpenter.sh/

# Install it, without waiting 
helm upgrade --install --namespace karpenter \
  karpenter karpenter/karpenter \
  --version 0.16.3 \
  --set clusterName=${CLUSTER_NAME} \
  --set aws.defaultInstanceProfile=$WORKER_PROFILE \
  --set settings.cluster-endpoint=$KUBE_ENDPOINT 

kubectl config set-context --current --namespace=$KARPENTER_NAMESPACE

# Patches
#

# 1) remove webhooks
oc delete validatingwebhookconfiguration validation.webhook.config.karpenter.sh
oc delete validatingwebhookconfiguration validation.webhook.provisioners.karpenter.sh
oc delete mutatingwebhookconfiguration defaulting.webhook.provisioners.karpenter.sh

# 2) remove invalid SCC
      # securityContext:
      #   fsGroup: 1000

oc patch deployment.apps/karpenter --type=json -p="[{'op': 'remove', 'path': '/spec/template/spec/securityContext'}]" 

# 3) Mount volumes/creds
oc set volume deployment.apps/karpenter --add -t secret -m /var/secrets/karpenter --secret-name=karpenter-aws-credentials --read-only=true

# 4) set env vars
oc set env deployment.apps/karpenter AWS_REGION=us-east-1 AWS_SHARED_CREDENTIALS_FILE=/var/secrets/karpenter/credentials CLUSTER_ENDPOINT=$KUBE_ENDPOINT

###############

AWS_REGION=us-east-1
INFRA_NAME=$(oc get infrastructure cluster -o jsonpath='{.status.infrastructureName}')
MACHINESET_NAME=$(oc get machineset -n openshift-machine-api -o jsonpath='{.items[0].metadata.name}')
MACHINESET_SUBNET_NAME=$(oc get machineset -n openshift-machine-api $MACHINESET_NAME -o json | jq -r '.spec.template.spec.providerSpec.value.subnet.filters[0].values[0]')
MACHINESET_SG_NAME=$(oc get machineset -n openshift-machine-api $MACHINESET_NAME -o json | jq -r '.spec.template.spec.providerSpec.value.securityGroups[0].filters[0].values[0]')
MACHINESET_INSTANCE_PROFILE=$(oc get machineset -n openshift-machine-api $MACHINESET_NAME -o json | jq -r '.spec.template.spec.providerSpec.value.iamInstanceProfile.id')
MACHINESET_AMI_ID=$(oc get machineset -n openshift-machine-api $MACHINESET_NAME -o json | jq -r '.spec.template.spec.providerSpec.value.ami.id')
MACHINESET_USER_DATA_SECRET=$(oc get machineset -n openshift-machine-api $MACHINESET_NAME -o json | jq -r '.spec.template.spec.providerSpec.value.userDataSecret.name')
MACHINESET_USER_DATA=$(oc get secret -n openshift-machine-api $MACHINESET_USER_DATA_SECRET -o jsonpath='{.data.userData}' | base64 -d)

cat <<EOF
AWS_REGION=$AWS_REGION
INFRA_NAME=$INFRA_NAME
MACHINESET_NAME=$MACHINESET_NAME
MACHINESET_SUBNET_NAME=$MACHINESET_SUBNET_NAME
MACHINESET_SG_NAME=$MACHINESET_SG_NAME
MACHINESET_INSTANCE_PROFILE=$MACHINESET_INSTANCE_PROFILE
MACHINESET_AMI_ID=$MACHINESET_AMI_ID
MACHINESET_USER_DATA_SECRET=$MACHINESET_USER_DATA_SECRET
MACHINESET_USER_DATA=$MACHINESET_USER_DATA
EOF

cat << EOF > ./kpt-provisioner-m6.yaml
# https://karpenter.sh/v0.30/concepts/provisioners/
apiVersion: karpenter.sh/v1alpha5
kind: Provisioner
metadata:
  name: "kpt-provisioner-m6"
spec:
  weight: 10
  consolidation:
    enabled: true
  labels:
    Environment: karpenter
  
  # Resource limits constrain the total size of the cluster.
  # Limits prevent Karpenter from creating new instances once the limit is exceeded.
  limits:
    resources:
      cpu: "128"
      memory: 256Gi
  labels:
    node-role.kubernetes.io/app: ""
    node-role.kubernetes.io/worker: ""
  requirements:
    - key: karpenter.k8s.aws/instance-category
      operator: In
      values: [m]
    - key: karpenter.k8s.aws/instance-generation
      operator: In
      values: ["6"]
    - key: "topology.kubernetes.io/zone"
      operator: In
      values: ["${AWS_REGION}a","${AWS_REGION}b","${AWS_REGION}c"]
    - key: "kubernetes.io/arch"
      operator: In
      values: ["amd64"]
    - key: "karpenter.sh/capacity-type"
      operator: In
      values: ["on-demand"]
    - key: "karpenter.k8s.aws/instance-cpu"
      operator: Gt
      values: ["2"]
    - key: "karpenter.k8s.aws/instance-memory"
      operator: Gt
      values: ["4096"]
    - key: "karpenter.k8s.aws/instance-pods"
      operator: Gt
      values: ["20"]
  providerRef:
    name: "kpt-${MACHINESET_NAME}"

---
apiVersion: karpenter.k8s.aws/v1alpha1
kind: AWSNodeTemplate
metadata:
  name: "kpt-${MACHINESET_NAME}"
spec:
  subnetSelector:
    kubernetes.io/cluster/${INFRA_NAME}: owned
    kubernetes.io/role/internal-elb: ""
  securityGroupSelector:
    Name: "${MACHINESET_SG_NAME}"
  instanceProfile: "${MACHINESET_INSTANCE_PROFILE}"
  amiFamily: Custom
  tags:
    cluster_name: $CLUSTER_NAME
    Environment: autoscaler
  amiSelector:
    aws-ids: "${MACHINESET_AMI_ID}"
  userData: |
    $MACHINESET_USER_DATA
EOF

# Check if all vars have been replaced in ./kpt-provisioner-m6.yaml
less ./kpt-provisioner-m6.yaml

# Apply the config

oc create -f ./kpt-provisioner-m6.yaml