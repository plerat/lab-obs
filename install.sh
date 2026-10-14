#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# 0. Minikube
# minikube start --cpus=4 --memory=8192 --disk-size=30g

# 1. Dépôts Helm
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts --force-update   # Prometheus + Alertmanager
helm repo add grafana-community    https://grafana-community.github.io/helm-charts  --force-update   # Loki, Tempo, Grafana
helm repo add open-telemetry       https://open-telemetry.github.io/opentelemetry-helm-charts --force-update   # Collector, démo
helm repo update

kubectl create namespace observability --dry-run=client -o yaml | kubectl apply -f -

# 2. Backends
helm upgrade --install prometheus prometheus-community/prometheus -n observability -f prometheus.yaml
helm upgrade --install loki       grafana-community/loki          -n observability -f loki.yaml
helm upgrade --install tempo      grafana-community/tempo         -n observability -f tempo.yaml

# 3. Collecte
helm upgrade --install otel-collector open-telemetry/opentelemetry-collector -n observability -f otel-collector.yaml

# 4. Visualisation
helm upgrade --install grafana grafana-community/grafana -n observability -f grafana.yaml

# 5. Application de démo
helm upgrade --install otel-demo open-telemetry/opentelemetry-demo -n demo --create-namespace -f otel-demo.yaml --timeout 10m

echo
echo "Grafana : NodePort 30030 (admin / admin)"
echo "Démo    : NodePort 30080"