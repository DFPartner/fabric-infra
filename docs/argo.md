This error occurs because Kustomize (the tool building your manifests) does not enable Helm chart processing by default for security reasons. You have to explicitly tell Argo CD to run Kustomize with the --enable-helm flag.

This is a global setting in Argo CD.

The Fix: Update Argo CD Configuration
You need to edit the argocd-cm ConfigMap in your cluster to enable this feature.

Run this command in your terminal:

```Bash
kubectl patch cm argocd-cm -n argocd --type merge -p '{"data":{"kustomize.buildOptions":"--enable-helm"}}'
kubectl patch cm argocd-cm -n argocd --type merge -p '{"data":{"kustomize.buildOptions":"--enable-helm --load-restrictor LoadRestrictionsNone"}}'
```

Alternative (Manual Edit): If you prefer to edit it manually with kubectl edit cm argocd-cm -n argocd, add this key to the data section:

```yaml
data:
kustomize.buildOptions: --enable-helm
```

Next Steps
Restart the Repo Server (Recommended): Argo CD caches build settings. To force it to pick up the change immediately, restart the repo server:

```Bash
kubectl rollout restart deploy argocd-repo-server -n argocd
```
Hard Refresh the App: Go to the Argo CD UI, navigate to your data-seaweedfs application, and click "Hard Refresh" (or in the "Refresh" dropdown).

Sync: The error should disappear, and you will see the generated manifests.