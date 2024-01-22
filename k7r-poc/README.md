Karpenter Proof-Of-Concept


# Setup IRSA
https://www.redhat.com/en/blog/running-pods-in-openshift-with-aws-iam-roles-for-service-accounts-aka-irsa

export OIDC_PROVIDER=$(oc get authentication.config.openshift.io cluster -ojson | jq -r .spec.serviceAccountIssuer | sed 's/https:\/\///')
echo "OIDC_PROVIDER=$OIDC_PROVIDER"


ccoctl aws create-iam-roles \
  --name=k7r-role \
  --region=us-east-1 \
  --credentials-requests-dir=credrequests  \
  --identity-provider-arn=arn:aws:iam::1234567890:oidc-provider/manual-sts-oidc.s3.us-east-1.amazonaws.com  \
  --output-dir=outputs



helm registry logout public.ecr.aws

helm upgrade --install karpenter oci://public.ecr.aws/karpenter/karpenter --version "${KARPENTER_VERSION}" --namespace "${KARPENTER_NAMESPACE}" --create-namespace \
  --set "settings.clusterName=${CLUSTER_NAME}" \
  --set "settings.interruptionQueue=${CLUSTER_NAME}" \
  --set controller.resources.requests.cpu=1 \
  --set controller.resources.requests.memory=1Gi \
  --set controller.resources.limits.cpu=1 \
  --set controller.resources.limits.memory=1Gi \
  --wait

ccoctl aws create-iam-roles \
  --name=prefix-role \
  --region=us-east-1 \
  --credentials-requests-dir=credrequests  \
--identity-provider-arn=arn:aws:iam::1234567890:oidc-provider/manual-sts-oidc.s3.us-east-1.amazonaws.com  \
  --output-dir=outputs