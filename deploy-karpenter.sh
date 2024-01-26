#!/bin/bash 

echo "Scaling down machine set"
oc scale machineset -n openshift-machine-api --replicas=0 $(oc get machineset -n openshift-machine-api -o jsonpath='{.items[2].metadata.name}')

export KARPENTER_NAMESPACE=karpenter
echo "Creating base namespace"
oc apply -f deploy-karpenter-base.k8s.yaml
kubectl config set-context --current --namespace=$KARPENTER_NAMESPACE

echo "Creating CSR approver"
oc apply -f deploy-karpenter-csr-approver.k8s.yaml

echo "Fetching cluster data..."
export KARPENTER_VERSION="v0.33.1"
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
echo "Adding karpenter repo..."
helm repo add karpenter https://charts.karpenter.sh/

# Install karpenter, without waiting 
helm upgrade --install --namespace karpenter \
  karpenter karpenter/karpenter \
  --version "$KARPENTER_CHART_VERSION" \
  --set "clusterName=${CLUSTER_NAME}" \
  --set "settings.clusterName=${CLUSTER_NAME}" \
  --set "settings.interruptionQueue=${CLUSTER_NAME}" \
  --set "aws.defaultInstanceProfile=$WORKER_PROFILE" \
  --set "settings.cluster-endpoint=$KUBE_ENDPOINT" 
#  --set controller.resources.requests.cpu=1 \
#  --set controller.resources.requests.memory=1Gi \
#  --set controller.resources.limits.cpu=1 \
#  --set controller.resources.limits.memory=1Gi \
#  --wait

echo "Patching karpenter"

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

echo "Fetching MachineSet data..."

AWS_REGION=$(aws configure get region)
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

envsubst < ./kpt-provisioner-m6.env.yaml  > ./.kpt-provisioner-m6.yaml

cat ./.kpt-provisioner-m6.yaml

# Apply the config

oc create -f ./.kpt-provisioner-m6.yaml

oc get provisioner
oc get AWSNodeTemplate