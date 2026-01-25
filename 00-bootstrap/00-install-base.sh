# ----------------------------------------- 1: Set up K3s on server (ssh-ed into server)-------
# 1.1 Update system
sudo apt update && sudo apt upgrade -y

# 1.2 Install basic utilities
sudo apt install -y curl unzip git

# 1.3 Disable Swap (Critical for K8s stability)
sudo swapoff -a
# Keep swap off after reboot by commenting out the swap line in fstab
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# 1.4 (Optional) If you use UFW firewall, open these internal ports
# K3s needs 6443 (API), 10250 (Metrics), and 8472 (Flannel VXLAN)
sudo ufw allow 6443/tcp
sudo ufw allow 10250/tcp
sudo ufw allow 8472/udp
# Allow your Gateway traffic
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp


# 1.5 and install K3s
curl -sfL https://get.k3s.io | sh -

# 1.6 copy the config somewhere you and kubectl can access it
# 1.6.1 Create .kube directory
mkdir -p ~/.kube
# 1.6.2 Copy the config from K3s location to standard K8s location
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
# 1.6.3 Change ownership to your current user
sudo chown $(id -u):$(id -g) ~/.kube/config
# 1.6.4 Set permission restrictive (good practice)
chmod 600 ~/.kube/config
# 1.6.5 And point KUBECONFIG to it
export KUBECONFIG=~/.kube/config

# 1.7 Check everything is running
# Check the node status
kubectl get nodes
# Check the system pods (Traefik etc.)
kubectl get pods -A

# ----------------------------------------- 2: Utilities -----------------------------------------
# The utilities (kubectl, helm and K9s) should be installed both on the server (for ssh-ing) and client
# 2.1 Download and install k9s
curl -sS https://webinstall.dev/k9s | bash
# You might need to source profile again or restart terminal
source ~/.config/envman/PATH.env

# 2.2 install Helm
sudo apt-get install curl gpg apt-transport-https --yes
curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
# OR on ubuntu just run
sudo snap install helm --classic

# ----------------------------------------- 3. Connect to K8s / K3s from client -----------------
# 3.1. Create the directory if it doesn't exist
mkdir -p ~/.kube
# 3.2 Copy the file securely (Replace 'bora@dsk.local' with your actual Linux username@server and name the config accordingly)
scp bora@dsk.local:~/.kube/config ~/.kube/dsk-config
# 3.3 Update the config with the correct server
# edit the file
# it should look like this (keep the long certificates, and replace all the "localhosts" and "defaults" with something like the "dsk-..."
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: [... keep this]
    server: https://192.168.1.38:6443 [REPLACE with your hostname or IP]
  name: dsk-cluster [REPLACE WITH YOUR NAME]
contexts:
- context:
    cluster: dsk-cluster [REPLACE WITH THE NAME ABOVE]
    user: dsk-admin  [REPLACE WITH YOUR ADMIN NAME]
  name: dsk [REPLACE WITH YOUR NAME]
current-context: dsk [NAME FROM ABOVE]
kind: Config
users:
- name: dsk-admin [ADMIN NAME FROM ABOVE]
  user:
    client-certificate-data: [... keep this]
    client-key-data:  [... keep this]
# 3.4 Check everything is running - this time from the client machine
# Check the node status
kubectl get nodes
# Check the system pods (Traefik, DNS, etc.)
kubectl get pods -A


# ----------------------------------------- 4. Set up basic cluster properties  -----------------
# 4.1 set up namespaces
kubectl apply -f 01-namespaces.yaml
# 4.2 install ArgoCD using helm
helm install argocd argo/argo-cd --namespace argocd --create-namespace -f values.yaml
# 4.3 get the temporary admin credentials (should be replaced later on)
kubectl get secret infra-repo-creds -n argocd -o jsonpath="{.data.sshPrivateKey}" | base64 -d
# 4.4 set up projects
kubectl apply -f 02-projects.yaml
# 4.5 patch argo
# Patch argo cd to enable longer timeout and enable helm and cross-app loading
# TODO this should be moved to ArgoCD ConfigMap
kubectl -n argocd set env deploy/argocd-repo-server ARGOCD_EXEC_TIMEOUT=180s
kubectl patch cm argocd-cm -n argocd --type merge \
  -p '{"data":{"kustomize.buildOptions":"--enable-helm --load-restrictor LoadRestrictionsNone"}}'
# 4.6 set up credential secret manager and certificate manager
kubectl apply -k 03-security.yaml
# 4.7 once the sealed-secret manager is up and running, create all secrets - see 04-secrets.sh


# ----------------------------------------- 5. and GO ...  -------------------------------------
# and go
kubectl apply -f root-app-<cluster name>.yaml



# ----------------------------------------- XXX. nuke it  -------------------------------------
# XXX.1 remove "finalizers" so that they do not block us
kubectl get ns argocd -o json | \
  jq '.spec.finalizers = []' | \
  kubectl replace --raw "/api/v1/namespaces/argocd/finalize" -f -
# XXX.2 Kill the old Controller (ArgoCD)
# We do this first so it doesn't try to "fight back" and recreate things we delete.
kubectl delete ns argocd
# wait until the thing finished
# if not, run the app by app finalizer
kubectl get applications -n argocd -o name | xargs -I % kubectl patch % -n argocd -p '{"metadata":{"finalizers":null}}' --type=merge

# XXX.3. Kill the Application Namespaces (if they still exist)
kubectl delete ns auth
kubectl delete ns monitoring
kubectl delete ns data
# Wait... This takes time. Kubernetes has to unmount volumes and stop containers.
# Watch the status until they are gone:
watch kubectl get ns

# XXX.4 Check CRDs and PVs
kubectl get crd | grep argo
kubectl get pv
# if necessary, delete those
ubectl delete crd <name>
ubectl delete pv <name>

# ... and continue with the step 4 ...



# ----------------------------------------- X. old stuff -------------------------------------
# replaced by the create-buckets job
kubectl exec -it -n data service/seaweedfs-master -- weed shell \
  -master=localhost:9333 \
  -filer=seaweedfs-filer-client.data:8888
s3.bucket.create -name tempo-traces
s3.bucket.create -name loki-chunks
s3.bucket.create -name loki-ruler
s3.bucket.create -name loki-admin

s3.bucket.list