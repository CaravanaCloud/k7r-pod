
Reference implementation of "getting started with Karpenter" https://karpenter.sh/docs/getting-started/getting-started-with-karpenter/

## Account Preparation

Use CloudFormation to set up the infrastructure needed by the EKS cluster. See CloudFormation for a complete description of what cloudformation.yaml does for Karpenter.

```
curl -fsSL https://raw.githubusercontent.com/aws/karpenter/"${KARPENTER_VERSION}"/website/content/en/preview/getting-started/getting-started-with-karpenter/cloudformation.yaml  > $TEMPOUT

aws cloudformation deploy \
  --stack-name "$STACK_NAME" \
  --template-file "${TEMPOUT}" \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides "ClusterName=${CLUSTER_NAME}"
```

## Cluster Creation
Create a Kubernetes service account and AWS IAM Role, and associate them using IRSA to let Karpenter launch instances.

```
envsubst < eks.env.yaml > .eks.yaml
eksctl create cluster -f .eks.yaml
```

```
export CLUSTER_ENDPOINT="$(aws eks describe-cluster --name ${CLUSTER_NAME} --query "cluster.endpoint" --output text)"
echo $CLUSTER_ENDPOINT 

eksctl utils write-kubeconfig --cluster="$CLUSTER_NAME"

kubectl get nodes
```

Add the Karpenter node role to the aws-auth configmap to allow nodes to connect.

```

```

Use AWS EKS managed node groups for the kube-system and karpenter namespaces. Uncomment fargateProfiles settings (and comment out managedNodeGroups settings) to use Fargate for both namespaces instead.

```
```

Set KARPENTER_IAM_ROLE_ARN variables.

```
export KARPENTER_IAM_ROLE_ARN="arn:${AWS_PARTITION}:iam::${AWS_ACCOUNT_ID}:role/${CLUSTER_NAME}-karpenter"
echo $KARPENTER_IAM_ROLE_ARN
```

Create a role to allow spot instances.

```
aws iam create-service-linked-role --aws-service-name spot.amazonaws.com
```

Run helm to install karpenter

```
helm registry logout public.ecr.aws

helm upgrade --install karpenter oci://public.ecr.aws/karpenter/karpenter --version "${KARPENTER_VERSION}" --namespace "${KARPENTER_NAMESPACE}" --create-namespace \
  --set "serviceAccount.annotations.eks\.amazonaws\.com/role-arn=${KARPENTER_IAM_ROLE_ARN}" \
  --set "settings.clusterName=${CLUSTER_NAME}" \
  --set "settings.interruptionQueue=${CLUSTER_NAME}" \
  --set controller.resources.requests.cpu=1 \
  --set controller.resources.requests.memory=1Gi \
  --set controller.resources.limits.cpu=1 \
  --set controller.resources.limits.memory=1Gi \
  --wait

```

## Create Node Group

```
envsubst < nodegroup.env.yaml > .nodegroup.yaml 
kubectl apply -f .nodegroup.yaml
```
## Scale up
```
kubectl apply -f deployment.yaml
```

```
kubectl scale deployment inflate --replicas 5
kubectl logs -f -n "${KARPENTER_NAMESPACE}" -l app.kubernetes.io/name=karpenter -c controller
```


## Troubleshooting

1- Ensure helm 3.13.2+

## Tear down
kubectl delete deployment inflate
kubectl logs -f -n "${KARPENTER_NAMESPACE}" -l app.kubernetes.io/name=karpenter -c controller

helm uninstall karpenter --namespace "${KARPENTER_NAMESPACE}"
aws cloudformation delete-stack --stack-name "Karpenter-${CLUSTER_NAME}"
aws ec2 describe-launch-templates --filters Name=tag:karpenter.k8s.aws/cluster,Values=${CLUSTER_NAME} |
    jq -r ".LaunchTemplates[].LaunchTemplateName" |
    xargs -I{} aws ec2 delete-launch-template --launch-template-name {}
eksctl delete cluster --name "${CLUSTER_NAME}"

aws cloudformation delete-stack --stack-name "Karpenter-${CLUSTER_NAME}"