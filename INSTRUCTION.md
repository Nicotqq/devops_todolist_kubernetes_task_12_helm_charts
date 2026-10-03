# How to validate the changes

Prerequisites: `docker`, `kind`, `kubectl`, `helm`.

1. Create the cluster, taint the mysql nodes, install ingress/metrics-server and deploy the chart:
   ```
   ./bootstrap.sh
   ```
2. Check the nodes, labels and taints:
   ```
   kubectl get nodes --show-labels
   kubectl describe nodes | grep -E "^Name:|Taints:"
   ```
   Nodes labeled `app=mysql` must have the taint `app=mysql:NoSchedule`.
3. Lint and render the chart:
   ```
   helm lint .infrastructure/helm-chart/todoapp
   helm template .infrastructure/helm-chart/todoapp -f .infrastructure/helm-chart/todoapp/values.yaml
   ```
4. Check the pods (2 `mysql-*` in namespace `mysql`, 2+ `todoapp-*` in namespace `todoapp`, all Running):
   ```
   kubectl get pods -n mysql -o wide
   kubectl get pods -n todoapp -o wide
   ```
5. Check HPA and Ingress:
   ```
   kubectl get hpa,ingress -n todoapp
   ```
6. Open the app at http://localhost/ (or the NodePort at http://localhost:30007/).
7. Regenerate `output.log` and verify it:
   ```
   kubectl get all,cm,secret,ing -A > output.log
   python .github/workflows/scripts/validate-output.py
   ```
8. Cleanup: `kind delete cluster --name todoapp`
