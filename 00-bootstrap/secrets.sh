# Fetch the certificate that can be used to seal the secrets
kubeseal \
  --controller-name=sealed-secrets-controller \
  --controller-namespace=kube-system \
  --fetch-cert > pub-sealed-secrets.pem



# Generate and seal the S3 secret
kubectl create secret generic seaweedfs-s3-secret \
  --from-literal=admin_password="SafePassword123!" \
  --from-literal=admin_user="admin" \
  --namespace data \
  --dry-run=client -o yaml > raw-sws3-secret.yaml

kubeseal --controller-name=sealed-secrets-controller \
    --controller-namespace=auth \
    --format=yaml \
    < raw-sws3-secret.yaml > sealed-sws3-secret.yaml


