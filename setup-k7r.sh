export PREFIX="k7r1irsa"
export TODAY="$(date +%d%b | tr '[:upper:]' '[:lower:]')"
export CLUSTER_NAME="$PREFIX$TODAY"
export AWS_PARTITION="aws"
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

aws iam create-role \
    --role-name "KarpenterNodeRole-${CLUSTER_NAME}" \
    --assume-role-policy-document file://node-trust-policy.json

aws iam attach-role-policy --role-name "KarpenterNodeRole-${CLUSTER_NAME}" \
    --policy-arn arn:${AWS_PARTITION}:iam::aws:policy/AmazonEKSWorkerNodePolicy

aws iam attach-role-policy --role-name "KarpenterNodeRole-${CLUSTER_NAME}" \
    --policy-arn arn:${AWS_PARTITION}:iam::aws:policy/AmazonEKS_CNI_Policy

aws iam attach-role-policy --role-name "KarpenterNodeRole-${CLUSTER_NAME}" \
    --policy-arn arn:${AWS_PARTITION}:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly

aws iam attach-role-policy --role-name "KarpenterNodeRole-${CLUSTER_NAME}" \
    --policy-arn arn:${AWS_PARTITION}:iam::aws:policy/AmazonSSMManagedInstanceCore


