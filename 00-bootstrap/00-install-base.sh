
# 1. Update system
sudo apt update && sudo apt upgrade -y

# 2. Install basic utilities
sudo apt install -y curl unzip git

# 3. Disable Swap (Critical for K8s stability)
sudo swapoff -a
# Keep swap off after reboot by commenting out the swap line in fstab
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# 4. (Optional) If you use UFW firewall, open these internal ports
# K3s needs 6443 (API), 10250 (Metrics), and 8472 (Flannel VXLAN)
sudo ufw allow 6443/tcp
sudo ufw allow 10250/tcp
sudo ufw allow 8472/udp
# Allow your Gateway traffic
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

curl -sfL https://get.k3s.io | sh -

# Create .kube directory
mkdir -p ~/.kube

# Copy the config from K3s location to standard K8s location
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config

# Change ownership to your current user
sudo chown $(id -u):$(id -g) ~/.kube/config

# Set permission restrictive (good practice)
chmod 600 ~/.kube/config

# Add useful alias and auto-completion to your shell
echo 'source <(kubectl completion bash)' >> ~/.bashrc
echo 'alias k=kubectl' >> ~/.bashrc
echo 'complete -F __start_kubectl k' >> ~/.bashrc
source ~/.bashrc







export KUBECONFIG=~/.kube/config



# Check the node status
kubectl get nodes

# Check the system pods (Traefik, DNS, etc.)
kubectl get pods -A


# Download and install k9s
curl -sS https://webinstall.dev/k9s | bash

# You might need to source profile again or restart terminal
source ~/.config/envman/PATH.env


sudo snap install helm --classic

# set up namespaces
kubectl apply -f 01-namespaces.yaml

# install argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml --request-timeout=180s
# create a deploy key to github
ssh-keygen -t ed25519 -C "argocd-deploy-key" -f argocd_key -N ""
kubectl create secret generic infra-repo-creds \
  -n argocd \
  --from-literal=type=git \
  --from-literal=url=git@github.com:BoraPerusic/k3s-df.git \
  --from-file=sshPrivateKey=argocd_key \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl get secret infra-repo-creds -n argocd -o jsonpath="{.data.sshPrivateKey}" | base64 -d


# set up projects
kubectl apply -f 02-projects.yaml

# and go
kubectl apply -f root-app.yaml



# install Helm
sudo apt-get install curl gpg apt-transport-https --yes
curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm



kubectl -n argocd set env deploy/argocd-repo-server ARGOCD_EXEC_TIMEOUT=180s


kubectl patch cm argocd-cm -n argocd --type merge \
  -p '{"data":{"kustomize.buildOptions":"--enable-helm --load-restrictor LoadRestrictionsNone"}}'

# replaced by the create-buckets job
kubectl exec -it -n data service/seaweedfs-master -- weed shell \
  -master=localhost:9333 \
  -filer=seaweedfs-filer-client.data:8888
s3.bucket.create -name tempo-traces
s3.bucket.create -name loki-chunks
s3.bucket.create -name loki-ruler
s3.bucket.create -name loki-admin

s3.bucket.list