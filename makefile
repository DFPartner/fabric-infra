# Makefile

init:
	kubectl apply -f 00-bootstrap/

install-monitoring:
	cd 01-platform/monitoring && ./install.sh

install-data:
	helm upgrade --install minio bitnami/minio -n data -f 01-platform/data/minio/values.yaml
	# Add other DBs here

deploy-apps:
	# Example of deploying a custom app using your local template
	helm upgrade --install user-service ./02-apps/templates/microservice-chart -n apps -f 02-apps/kotlin-services/user-service.yaml

status:
	kubectl get pods -A

monitoring:
# Note: The service name usually starts with the release name "prom-stack"
    kubectl port-forward -n monitoring svc/prom-stack-grafana 3000:80

get-secret:
    kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo