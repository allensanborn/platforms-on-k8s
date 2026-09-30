# Argo CD 3.6 is the first release whose application controller exports sync spans over OTLP
# (argoproj/argo-cd#28396). Move to v3.6.0 once it is released.
ARGOCD_VERSION ?= v3.6.0-rc1
ARGO_ROLLOUTS_VERSION ?= v1.10.0
KUBE_PROMETHEUS_STACK_VERSION ?= 91.8.2
GRAFANA_PORT_FORWARD ?= 3000

.PHONY: install
install: install-operators install-observability install-argocd install-argo-rollouts
	@echo ""
	@echo "Installed. Next: kubectl apply -f argocd/application.yaml"

# CloudNativePG and Strimzi back the Conference application's PostgreSQL and Kafka (see chapter 2)
.PHONY: install-operators
install-operators:
	helm upgrade --install cnpg cloudnative-pg \
	  --repo https://cloudnative-pg.github.io/charts --version 0.29.1 \
	  --namespace cnpg-system --create-namespace --wait
	helm upgrade --install strimzi oci://quay.io/strimzi-helm/strimzi-kafka-operator \
	  --version 1.2.0 --namespace strimzi --create-namespace \
	  --set watchAnyNamespace=true --wait

.PHONY: install-observability
install-observability:
	helm upgrade --install kube-prometheus-stack kube-prometheus-stack \
	  --repo https://prometheus-community.github.io/helm-charts --version $(KUBE_PROMETHEUS_STACK_VERSION) \
	  --namespace monitoring --create-namespace -f observability/kube-prometheus-stack-values.yaml --wait --timeout 10m
	kubectl apply -f observability/grafana-dashboard.yaml
	kubectl apply -f observability/jaeger.yaml
	kubectl wait --for=condition=Available deployment/jaeger -n observability --timeout=300s

.PHONY: install-argocd
install-argocd:
	kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -n argocd --server-side --force-conflicts \
	  -f https://raw.githubusercontent.com/argoproj/argo-cd/$(ARGOCD_VERSION)/manifests/install.yaml
	kubectl apply -f argocd/argocd-cmd-params-cm.yaml
	kubectl apply -f argocd/servicemonitor.yaml
	kubectl apply -f argocd/conference-chart-repository.yaml
	# pick up otlp.address from argocd-cmd-params-cm
	kubectl rollout restart -n argocd statefulset/argocd-application-controller deployment/argocd-repo-server deployment/argocd-server
	kubectl rollout status -n argocd statefulset/argocd-application-controller --timeout=300s
	kubectl rollout status -n argocd deployment/argocd-repo-server --timeout=300s
	kubectl rollout status -n argocd deployment/argocd-server --timeout=300s

.PHONY: install-argo-rollouts
install-argo-rollouts:
	kubectl create namespace argo-rollouts --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -n argo-rollouts --server-side \
	  -f https://github.com/argoproj/argo-rollouts/releases/download/$(ARGO_ROLLOUTS_VERSION)/install.yaml
	kubectl wait --for=condition=Available deployment/argo-rollouts -n argo-rollouts --timeout=300s

.PHONY: port-forward-grafana
port-forward-grafana:
	@echo "Open Grafana in your browser: http://localhost:$(GRAFANA_PORT_FORWARD) (admin/admin)"
	kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana $(GRAFANA_PORT_FORWARD):80

.PHONY: port-forward-jaeger
port-forward-jaeger:
	@echo "Open Jaeger in your browser: http://localhost:16686"
	kubectl -n observability port-forward svc/jaeger 16686

.PHONY: port-forward-prometheus
port-forward-prometheus:
	@echo "Open Prometheus in your browser: http://localhost:9090"
	kubectl -n monitoring port-forward svc/kube-prometheus-stack-prometheus 9090

.PHONY: port-forward-argocd
port-forward-argocd:
	@echo "Open Argo CD in your browser: https://localhost:8080 (admin / make argocd-password)"
	kubectl -n argocd port-forward svc/argocd-server 8080:443

.PHONY: argocd-password
argocd-password:
	@kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
