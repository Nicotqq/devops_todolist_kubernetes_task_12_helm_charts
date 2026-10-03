#!/bin/bash
set -e

# 1. Create the kind cluster
kind create cluster --name todoapp --config cluster.yml

# 2. Inspect nodes: labels and taints
kubectl get nodes --show-labels
kubectl describe nodes | grep -E "^Name:|Taints:"

# 3. Taint the nodes labeled app=mysql
kubectl taint nodes -l app=mysql app=mysql:NoSchedule --overwrite
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints

# 4. Install the Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s

# 5. Install metrics-server (required by the HPA); kind needs --kubelet-insecure-tls
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl patch -n kube-system deployment metrics-server --type=json \
  -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'

# 6. Deploy the todoapp helm chart (mysql is its sub-chart)
helm dependency update .infrastructure/helm-chart/todoapp || true
helm upgrade --install todoapp .infrastructure/helm-chart/todoapp \
  -f .infrastructure/helm-chart/todoapp/values.yaml

# 7. Wait for workloads and save the cluster state
kubectl -n mysql rollout status statefulset/mysql --timeout=300s
kubectl -n todoapp rollout status deployment/todoapp --timeout=300s
kubectl get all,cm,secret,ing -A > output.log
