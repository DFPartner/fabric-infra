# Fetch the certificate that can be used to seal the secrets
kubeseal \
  --controller-name=sealed-secrets-controller \
  --controller-namespace=auth \
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


# Docker Hub
kubectl create secret generic docker-hub-creds \
  --namespace argocd \
  --from-literal=url=registry-1.docker.io \
  --from-literal=username=boraperusic \
  --from-literal=password="PASSWORD HERE" \
  --from-literal=type=helm \
  --from-literal=name=docker-hub \
  --from-literal=enableOCI="true"

kubectl label secret docker-hub-creds -n argocd argocd.argoproj.io/secret-type=repository

# PostgreSQL for Keycloak
kubectl create secret generic keycloak-db-creds \
  --from-literal=postgres-password="PgSqlAdminSecretHere" \
  --from-literal=password="KeycloakPgSecretHere" \
  --from-literal=name="keycloak" \
  --from-literal=database="keycloak" \
  --namespace auth \
  --dry-run=client -o yaml > raw-keycloak-db-creds.yaml

kubeseal --controller-name=sealed-secrets-controller \
  --controller-namespace=auth \
  --format=yaml < raw-keycloak-db-creds.yaml > sealed-keycloak-db-creds.yaml

# Keycloak admin
kubectl create secret generic keycloak-admin-creds \
  --from-literal=admin-password=admin \
  --namespace auth \
  --dry-run=client -o yaml > raw-keycloak-admin-creds.yaml

kubeseal --controller-name=sealed-secrets-controller \
  --controller-namespace=auth \
  --format=yaml < raw-keycloak-admin-creds.yaml > sealed-keycloak-admin-creds.yaml


# Monitoring (done in Loki, used by Tempo)
# Run this locally to create the encrypted file
kubectl create secret generic monitoring-creds \
  --from-literal=access_key_id="admin" \
  --from-literal=secret_access_key="SafePassword123!" \
  --namespace monitoring \
  --dry-run=client -o yaml > raw-mon-creds.yaml

kubeseal --cert=pub-sealed-secrets.pem --format=yaml < raw-mon-creds.yaml > sealed-mon-creds.yaml


# Grafana (part of Prometheus Stack)
kubectl create secret generic grafana-admin-creds \
  --from-literal=admin-user=admin \
  --from-literal=admin-password=SafePassword123! \
  --namespace monitoring \
  --dry-run=client -o yaml > raw-grafana-creds.yaml

kubeseal --controller-name=sealed-secrets-controller \
  --controller-namespace=auth \
  --format=yaml < raw-grafana-creds.yaml > sealed-grafana-creds.yaml

# Grafana ouath (Keycloak) secret (when keycloak secret is up and running)
kubectl create secret generic grafana-oauth-keycloak-creds \
  --from-literal=client_id=grafana \
  --from-literal=client_secret=FcOLfvEuX2n6JZnrQg89g8euNRKcZtxY \
  --namespace monitoring \
  --dry-run=client -o yaml > raw-grafana-oauth-keycloak-creds.yaml


kubeseal --controller-name=sealed-secrets-controller \
  --controller-namespace=auth \
  --format=yaml < raw-grafana-oauth-keycloak-creds.yaml > sealed-grafana-oauth-keycloak-creds.yaml
