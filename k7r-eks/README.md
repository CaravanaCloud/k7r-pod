# https://karpenter.sh/docs/getting-started/getting-started-with-karpenter/

```


export CLUSTER_ENDPOINT="$(aws eks describe-cluster --name ${CLUSTER_NAME} --query "cluster.endpoint" --output text)"
export KARPENTER_IAM_ROLE_ARN="arn:${AWS_PARTITION}:iam::${AWS_ACCOUNT_ID}:role/${CLUSTER_NAME}-karpenter"

echo $CLUSTER_ENDPOINT $KARPENTER_IAM_ROLE_ARN

```

Use CloudFormation to set up the infrastructure needed by the EKS cluster. See CloudFormation for a complete description of what cloudformation.yaml does for Karpenter.

```
curl -fsSL https://raw.githubusercontent.com/aws/karpenter/"${KARPENTER_VERSION}"/website/content/en/preview/getting-started/getting-started-with-karpenter/cloudformation.yaml  > $TEMPOUT

aws cloudformation deploy \
  --stack-name "Karpenter-${CLUSTER_NAME}" \
  --template-file "${TEMPOUT}" \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides "ClusterName=${CLUSTER_NAME}"
```

Create a Kubernetes service account and AWS IAM Role, and associate them using IRSA to let Karpenter launch instances.

```
envsubst < eks.env.yaml > .eks.yaml
eksctl create cluster -f .eks.yaml
```

Add the Karpenter node role to the aws-auth configmap to allow nodes to connect.

```
```

Use AWS EKS managed node groups for the kube-system and karpenter namespaces. Uncomment fargateProfiles settings (and comment out managedNodeGroups settings) to use Fargate for both namespaces instead.

```
```

Set KARPENTER_IAM_ROLE_ARN variables.

```
```

Create a role to allow spot instances.

```
```

Run helm to install karpenter

```
```
