oc delete ClusterAutoscaler default

export WORKER_ROLE_NAME="k7r-worker-role"

aws iam create-role --role-name "$WORKER_ROLE_NAME" \
    --assume-role-policy-document file://ec2-trust-policy.json \
    --output "json" | tee .create-role.json
ROLE_ARN="$(jq -r '.Role.Arn' .create-role.json)"
echo ROLE_ARN=$ROLE_ARN

export WORKER_ROLE_ARN="$(jq -r '.Role.Arn' .create-role.json)"
envsubst < karpenter-base.policy.env.json > .karpenter-base.policy.json
jq . .karpenter-base.policy.json

# create user with this policy
aws iam create-policy --policy-name "k7r-user-policy" \
    --policy-document file://.karpenter-base.policy.json \
    --output "json" | tee .create-policy.json

# get policy arn
export POLICY_ARN="$(jq -r '.Policy.Arn' .create-policy.json)"
echo "POLICY_ARN: $POLICY_ARN"

# create user with this policy
IAM_USER_NAME="k7r-user"
aws iam create-user --user-name $IAM_USER_NAME \
    --output "json" | tee .create-user.json

# get user arn
export USER_ARN="$(jq -r '.User.Arn' .create-user.json)"
echo "USER_ARN: $USER_ARN"

# create access key
aws iam create-access-key --user-name  $IAM_USER_NAME \
    --output "json" | tee .create-access-key.json

export IAM_AWS_ACCESS_KEY_ID="$(jq -r '.AccessKey.AccessKeyId' .create-access-key.json)"
export IAM_AWS_SECRET_ACCESS_KEY="$(jq -r '.AccessKey.SecretAccessKey' .create-access-key.json)"

aws sts get-caller-identity


aws iam attach-user-policy \
    --user-name $IAM_USER_NAME \
    --policy-arn  $POLICY_ARN
    
aws iam attach-user-policy \
    --user-name $IAM_USER_NAME \
    --policy-arn 'arn:aws:iam::aws:policy/AdministratorAccess'

OC_NS="k7r-system"

oc new-project $OC_NS

# ccoctl aws create-iam-roles \
#   --name=prefix-role \
#  --region=us-east-1 \
#  --credentials-requests-dir=credrequests  \
#    --identity-provider-arn=arn:aws:iam::1234567890:oidc-provider/manual-sts-oidc.s3.us-east-1.amazonaws.com  \
#  --output-dir=outputs
